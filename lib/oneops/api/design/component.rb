class OO::Api::Design::Component < OO::Api::Base
  qualifiers :assembly, :platform, :type
  support_sticky 'design'
  attr_accessor :sibling_depends_on

  def self.all(assembly, platform)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/components")
    return ok ? data.map {|e| new(assembly, platform, nil, e)} : []
  end

  def self.find(assembly, platform, component)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}")
    ok ? new(assembly, platform, nil, data) : nil
  end

  def self.build(assembly, platform, type)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/components/new?template_name=#{type}")
    ok ? new(assembly, platform, type, data) : nil
  end

  def save
    ci_id = data[:ciId]
    payload = {:cms_dj_ci => data, :sibling_depends_on => (sibling_depends_on || []).to_a}
    ok = if ci_id.blank?
      payload[:template_name] = type
      self.class.request(:post, "assemblies/#{assembly}/design/platforms/#{platform}/components", payload, self)
    else
      self.class.request(:put, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{ci_id}", payload, self)
    end
    return ok
  end

  def destroy
    return self.class.request(:delete, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{data[:ciId]}", '', self)
  end

  def as_pretty(options)
    result = super
    result[:sibling_depends_on] = sibling_depends_on if sibling_depends_on
    result
  end
end
