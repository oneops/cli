require 'base64'
require 'active_support/hash_with_indifferent_access'

module OO::Api
  class OO::Api::Base
    class << self
      def qualifiers(*names)
        if names.present?
          @qualifiers = names
          attr_accessor *names
        end
        @qualifiers
      end

      def support_sticky(owner)
        @sticky = owner
      end

      def sticky
        @sticky
      end

      def request(method, path, payload = '', instance = nil)
        headers                  = {}
        headers['Authorization'] = "Basic #{Base64.encode64("#{OO::Api::Config.user}:#{OO::Api::Config.password}")}"
        headers['Content-Type']  = 'application/json'
        headers['Accept']        = 'application/json'

        if prefix
          url = "#{OO::Api::Config.site}/#{prefix}/#{path}"
        else
          url = "#{OO::Api::Config.site}/#{path}"
        end
        opts = {:method     => method,
                :url        => url,
                :payload    => payload,
                :headers    => headers,
                :verify_ssl => OO::Api::Config.verify_ssl}
        timeout = OO::Api::Config.timeout
        if timeout
          timeout = timeout.to_i
          opts[:timeout] = timeout > 0 ? timeout : nil
        end
        status, body = perform_http_request(opts)

        if status >= 200 && status < 210
          if url =~ (/\.yaml(\?.*)?$/)
            data = body
          else
            data = JSON.parse(body)
          end
          if instance
            instance.data = data
            return true
          else
            return true, data
          end
        elsif status == 422
          errors = JSON.parse(body)['errors']
          if instance
            instance.errors = errors
            return false
          else
            return false, errors
          end
        elsif status == 401
          raise UnauthroizedException.new(url)
        elsif status == 404
          raise NotFoundException.new(url)
        else
          raise ApiException.new("#{method.to_s.upcase} #{url}\n#{status}\n#{body.to_s}")
        end
      end


      private

      def perform_http_request(request)
        result = nil
        RestClient::Request.execute(request) do |resp, req|
          result = [resp.code, resp.body]
          if OO::Api::Config.debug
            puts '>>>'
            puts 'Skipping SSL verification'.yellow unless OO::Api::Config.verify_ssl
            puts "REQUEST: #{req.method} #{req.url}"
            puts "REQUEST_BODY: #{request[:payload].inspect}" if request[:payload]
            puts "RESPONSE_HEADERS:"
            resp.headers.each do |key, value|
              puts "    #{key} : #{value}"
            end
            puts "RESPONSE: [#{resp.code}]"
            begin
              puts JSON.parse(resp.body).to_pretty
            rescue
              puts "#{resp.body}"
            end
            puts '<<<'
          end
        end
        return result
      end
    end

    attr_reader :data
    attr_accessor :errors

    def initialize(*args)
      qualifiers = self.class.qualifiers
      qualifiers.each_with_index {|name, i| send("#{name}=", args[i])} if qualifiers.present?
      self.data = args.last
    end

    def method_missing(method_name, *args)
      if method_name.to_s.end_with?('=')
        @data[method_name.to_s[0...-1]] = args[0]
        return
      elsif @data && @data.size > 0
        value = @data[method_name]
        return value unless value.nil?
      end
      super
    end

    def as_pretty(options)
      extra = options[:extra] || {}
      #extra.merge({ :name => full_name }) if data.include?(:ciName)
      return data.merge(extra).as_pretty(options)
    end

    def data=(data)
      @data = (data && data.is_a?(Hash)) ? ActiveSupport::HashWithIndifferentAccess.new(data) : ActiveSupport::HashWithIndifferentAccess.new
      sticky = self.class.sticky
      if sticky.present?
        @data[:ciAttrProps] = {:owner => {}} if @data[:ciAttrProps].blank?
        @data[:ciAttrProps][:owner] = {} if @data[:ciAttrProps][:owner].blank?
        @data[:ciAttributes] = StickyAttributeHash.new(@data[:ciAttributes] || HashWithIndifferentAccess.new, @data[:ciAttrProps][:owner], sticky)
      end
    end


    protected

    def full_name
      return @full_name if @full_name
      full_name = self.class.qualifiers.present? ? self.class.qualifiers.map {|q| send(q)} : []
      full_name << data[:ciName]
      @full_name = full_name.join('/')
    end

    def self.prefix
      OO::Api::Config.organization
    end

    class StickyAttributeHash < ActiveSupport::HashWithIndifferentAccess
      def initialize(data, sticky_map, sticky_value)
        super(data)

        @sticky_map   = sticky_map
        @sticky_value = sticky_value
      end

      # Sticky assignment implemented via use of '_' suffix.  For example given an attribute 'bar' of some model
      # instance 'foo':
      #     foo.ciAttributes.bar = '123'   # regular non-sticky assignment (any possible previously existing 'stickiness' for this attribute is removed)
      #     foo.ciAttributes.bar_ = '123'  # sticky assignment
      #     foo.ciAttributes.bar           # returns value of 'foo' regardless of whether it is sticky or not
      #     foo.ciAttributes.bar_          # returns value of 'foo' if it is sticky, returns nil if it is not sticky or not assigned at all.
      #
      def method_missing(method_name, *args)
        if method_name.to_s.end_with?('=')
          self[method_name.to_s[0...-1]] = args[0]
        else
          self[method_name.to_s]
        end
      end

      def [](key)
        attr_name = key
        if key.end_with?('_')
          attr_name = attr_name[0...-1]
          return nil unless @sticky_map[attr_name] == @sticky_value
        end
        super(attr_name)
      end

      def []=(key, value)
        attr_name = key
        if attr_name.end_with?('_')
          attr_name = attr_name[0...-1]
          @sticky_map[attr_name] = @sticky_value
        else
          @sticky_map[attr_name] = ''
        end

        super(attr_name, value)
      end

      def as_pretty(options)
        return self.inject(HashWithIndifferentAccess.new) do |h, kv|
          h["#{kv[0]}#{'_' if @sticky_map[kv[0]] == @sticky_value}"] = kv[1]
          h
        end
      end
    end
  end
end
