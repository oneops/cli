class OO::Api::Transition::Deployment < OO::Api::Base
  qualifiers :assembly, :environment

  def self.all(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/deployments")
    ok ? data.map {|e| new(assembly, environment, e)} : []
  end

  def self.find(assembly, environment, release)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/#{release}")
    ok ? new(assembly, environment, data) : nil
  end

  def self.latest(assembly, environment)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/latest")
    ok ? new(assembly, environment, data) : nil
  end

  def create
    self.class.request(:post, "assemblies/#{assembly}/transition/environments/#{environment}/deployments", {:cms_deployment => data}, self)
  end

  def update(state)
    self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/#{data[:deploymentId]}", {:cms_deployment => {:releaseId => data[:releaseId], :deploymentState => state}}, self)
  end

  def cancel
    self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/#{data[:deploymentId]}", {:cms_deployment => {:releaseId => data[:releaseId], :deploymentState => 'canceled'}}, self)
  end

  def retry
    self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/#{data[:deploymentId]}", {:cms_deployment => {:releaseId => data[:releaseId], :deploymentState => 'active'}}, self)
  end

  def pause
    self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/#{data[:deploymentId]}", {:cms_deployment => {:releaseId => data[:releaseId], :deploymentState => 'paused'}}, self)
  end

  def resume
    self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/deployments/#{data[:deploymentId]}", {:cms_deployment => {:releaseId => data[:releaseId], :deploymentState => 'active'}}, self)
  end

end
