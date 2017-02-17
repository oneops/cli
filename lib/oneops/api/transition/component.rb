class OO::Api::Transition::Component < OO::Api::Base
  SCALE_ATTRIBUTES = %w(pct_dpmt current min max step_up step_down)

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

  def depends_on
    ok, depends_on_data = self.class.request(:get, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components/#{data[:ciId]}/depends_on")

    return ok && convert_scale_response(depends_on_data)
  end

  def update_depends_on(to_ci, depends_on_attrs)
    depends_on_data = {:depends_on => {to_ci => {:relationAttributes => depends_on_attrs.slice(*SCALE_ATTRIBUTES)}}}
    ok, data = self.class.request(:put, "assemblies/#{assembly}/transition/environments/#{environment}/platforms/#{platform}/components/#{self.data[:ciId]}/update_depends_on", depends_on_data)
    say data
    if ok
      return convert_scale_response(data)
    else
      self.data = data
      return false
    end
  end

  def as_pretty(options)
    result = super
    result[:sibling_depends_on] = sibling_depends_on if sibling_depends_on
    result
  end

  private

  def convert_scale_response(depends_on_data)
    depends_on_data.inject({}) do |h, r|
      h[r['toCi']['ciName']] = r['relationAttributes'].slice(*SCALE_ATTRIBUTES)
      h
    end
  end
end
