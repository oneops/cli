class OO::Api::Operations::Instance < OO::Api::Base
  qualifiers :assembly, :environment, :platform, :component

  def self.all(assembly, environment, platform, component)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components/#{component}/instances?instances_state=all")
    return ok ? data.map {|e| new(assembly, environment, platform, component, e)} : []
  end

  def self.find(assembly, environment, platform, component, instance)
    ok, data = request(:get, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components/#{component}/instances/#{instance}")
    ok ? new(assembly, environment, platform, component, data) : nil
  end

  def replace
    self.class.request(:put, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components/#{component}/instances/#{data[:ciId]}/state", {:state => 'replace'}, self)
  end

  def unreplace
    self.class.request(:put, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components/#{component}/instances/#{data[:ciId]}/state", {:state => 'default'}, self)
  end
   
  def destroy
    self.class.request(:delete, "assemblies/#{assembly}/operations/environments/#{environment}/platforms/#{platform}/components/#{component}/instances/#{data[:ciId]}", '', self)
  end 
end
