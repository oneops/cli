class OO::Api::Operations::Environment < OO::Api::Base
  qualifiers :assembly
  attr_accessor :primary_cloud
  attr_accessor :secondary_cloud
  attr_accessor :platform_availability

  def self.all(assembly)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments")
    return ok ? data.map {|e| new(assembly, e)} : []
  end

  def self.find(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}")
    return nil unless ok
    environment = new(assembly, data)
    environment.primary_cloud = environment.data.delete(:primary_cloud)
    secondary = environment.data.delete(:secondary_cloud)
    environment.secondary_cloud = secondary if secondary
    return environment
  end

end
