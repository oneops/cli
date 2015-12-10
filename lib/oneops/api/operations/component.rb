class OO::Api::Operations::Component < OO::Api::Base
  qualifiers :assembly, :environment, :platform

  def self.all(assembly, environment, platform)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components")
    return ok ? data.map {|e| new(assembly, environment, platform, nil, e)} : []
  end

  def self.find(assembly, environment, platform, component)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components/#{component}")
    ok ? new(assembly, environment, platform, nil, data) : nil
  end

end
