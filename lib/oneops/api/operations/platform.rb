class OO::Api::Operations::Platform < OO::Api::Base
  qualifiers :assembly, :environment

  def self.all(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}/platforms")
    return ok ? data.map {|e| new(assembly, environment, e)} : []
  end

  def self.find(assembly, environment, platform)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}")
    return nil unless ok
    platform = new(assembly, environment, data)
    return platform
  end

  # TODO add activate and terminate

end
