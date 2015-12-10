class OO::Api::Design::Attachment < OO::Api::Base
  qualifiers :assembly, :platform, :component

  def self.all(assembly, platform, component)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}/attachments")
    return ok ? data.map {|e| new(assembly, platform, component, e)} : []
  end

  def self.find(assembly, platform, component, attachment)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}/attachments/#{attachment}")
    ok ? new(assembly, platform, component, data) : nil
  end

  def self.build(assembly, platform, component)
    ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}/attachments/new")
    ok ? new(assembly, platform, component, data) : nil
  end

  def save
    ci_id = data[:ciId]
    payload = {:cms_dj_ci => data}
    ok = if ci_id.blank?
      self.class.request(:post, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}/attachments", payload, self)
    else
      self.class.request(:put, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}/attachments/#{ci_id}", payload, self)
    end
    return ok
  end

  def destroy
    return self.class.request(:delete, "assemblies/#{assembly}/design/platforms/#{platform}/components/#{component}/attachments/#{data[:ciId]}", '', self)
  end
end
