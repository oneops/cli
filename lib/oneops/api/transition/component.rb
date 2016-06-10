class OO::Api::Transition::Component < OO::Api::Base
  qualifiers :assembly, :environment, :platform
  support_sticky 'manifest'
  attr_accessor :sibling_depends_on

  def self.all(assembly, environment, platform)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components")
    return ok ? data.map {|e| new(assembly, environment, platform, nil, e)} : []
  end

  def self.find(assembly, environment, platform, component)
    ok, data = request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components/#{component}")
    ok ? new(assembly, environment, platform, nil, data) : nil
  end

  def save
    ci_id = data[:ciId]
    payload = {:cms_dj_ci => data, :sibling_depends_on => (sibling_depends_on || []).to_a}
    self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components/#{ci_id}", payload, self)
  end

  def touch
    ci_id = data[:ciId]
    self.class.request(:post, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components/#{ci_id}/touch", nil, self)
  end

  def deploy
    ci_name = data[:ciName]
    self.class.request(:post, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components/#{ci_name}/deploy", nil, self)
  end

  def as_pretty(options)
    result = super
    result[:sibling_depends_on] = sibling_depends_on if sibling_depends_on
    result
  end
end
