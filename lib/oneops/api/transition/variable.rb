class OO::Api::Transition::Variable < OO::Api::Variable
  qualifiers :assembly, :environment, :platform
  support_sticky 'manifest'

  def self.all(assembly, environment, platform)
    if platform
      ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/variables")
    else
      ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/variables")
    end
    return ok ? data.map {|e| new(assembly, environment, platform, e)} : []
  end

  def self.find(assembly, environment, platform, variable)
    if platform
      ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/variables/#{variable}")
    else
      ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/variables/#{variable}")
    end
    return nil unless ok
    variable = new(assembly, environment, platform, data)
    return variable
  end

  def save
    if platform
      return self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/variables/#{data[:ciId]}", {:cms_dj_ci => data}, self)
    else
      return self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/variables/#{data[:ciId]}", {:cms_dj_ci => data}, self)
    end
  end
end
