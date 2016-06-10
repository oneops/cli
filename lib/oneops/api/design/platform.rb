class OO::Api::Design::Platform < OO::Api::Base
  qualifiers :assembly
  support_sticky 'design'
  attr_accessor :links_to

  def self.all(assembly)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms")
    return ok ? data.map {|e| new(assembly, e)} : []
  end

  def self.find(assembly, platform)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}")
    return nil unless ok
    platform = new(assembly, data)
    platform.links_to = platform.data.delete(:links_to)
    return platform
  end

  def save
    ci_id = data[:ciId]
    ok = if ci_id.blank?
      self.class.request(:post, "assemblies/#{assembly}/design/platforms", {:cms_dj_ci => data, :links_to => (links_to || []).to_a}, self)
    else
      self.class.request(:put, "assemblies/#{assembly}/design/platforms/#{ci_id}", {:cms_dj_ci => data, :links_to => (links_to || []).to_a}, self)
    end
    return ok
  end

  def destroy
    ci_id = data[:ciId]
    return self.class.request(:delete, "assemblies/#{assembly}/design/platforms/#{ci_id}", '', self)
  end

  def clone(dest_assembly, platform = nil)
    to_assembly = dest_assembly.presence || assembly
    ok, data = self.class.request(:post, "assemblies/#{assembly}/design/platforms/#{self.data[:ciId]}/clone", {:to_assembly_id => to_assembly, :to_ci_name => platform.presence || self.data[:ciName]})
    if ok
      return self.class.new(assembly, data)
    else
      self.errors = data
      return nil
    end
  end

  def as_pretty(options)
    options[:extra] = {:links_to => links_to} if links_to
    super(options)
  end
end
