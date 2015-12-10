class OO::Api::Transition::Platform < OO::Api::Base
  qualifiers :assembly, :environment

  def self.all(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms")
    return ok ? data.map {|e| new(assembly, environment, e)} : []
  end

  def self.find(assembly, environment, platform)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}")
    return nil unless ok
    platform = new(assembly, environment, data)
    return platform
  end

  def save
    return self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{data[:ciId]}", {:cms_dj_ci => data}, self)
  end

  def toggle
    self.class.request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{self.ciName}/toggle")
  end

  # TODO add activate and terminate

end
