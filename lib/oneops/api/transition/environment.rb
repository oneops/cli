class OO::Api::Transition::Environment < OO::Api::Base
  qualifiers :assembly
  attr_accessor :clouds
  attr_accessor :platform_availability

  def self.all(assembly)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments")
    return ok ? data.map {|e| new(assembly, e)} : []
  end

  def self.find(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}")
    return nil unless ok
    environment = new(assembly, data)
    environment.clouds = environment.data.delete(:clouds)
    return environment
  end

  def save
    ci_id = data[:ciId]
    body = {:cms_ci => data}
    body[:clouds] = clouds if clouds
    if ci_id.blank?
      body[:platform_availability] = platform_availability.presence || {:dummy => ''} if platform_availability
      self.class.request(:post, "assemblies/#{assembly}/transition/environments", body, self)
    else
      self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{ci_id}", body, self)
    end
  end

  def destroy
    return self.class.request(:delete, "assemblies/#{assembly}/transition/environments/#{data[:ciId]}", '', self)
  end

  def pull_design
    return self.class.request(:post, "assemblies/#{assembly}/transition/environments/#{data[:ciId]}/pull", {:platform_availability => platform_availability}, self)
  end

  def commit(description = nil)
    return self.class.request(:post, "assemblies/#{assembly}/transition/environments/#{data[:ciId]}/commit", {:desc => description}, self)
  end

  def enable
    return self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{data[:ciId]}/enable", '', self)
  end

  def disable
    return self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{data[:ciId]}/disable", '', self)
  end

  def as_pretty(options)
    options[:extra] = {:clouds => clouds}
    super(options)
  end
end
