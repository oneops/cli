class OO::Api::Transition::Release < OO::Api::Base
  qualifiers :assembly, :environment

  def self.all(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/releases")
    ok ? data.map {|e| new(assembly, environment, e)} : []
  end

  def self.find(assembly, environment, release)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/releases/#{release}")
    ok ? new(assembly, environment, data) : nil
  end

  def self.latest(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/releases/latest")
    ok ? new(assembly, environment, data) : nil
  end

  def self.bom(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/releases/bom")
    ok ? new(assembly, environment, data) : nil
  end

  def discard
    self.class.request(:post, "assemblies/#{assembly}/transition/environments/#{environment}/releases/#{data[:releaseId]}/discard", '', self)
  end
end
