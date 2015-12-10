class OO::Api::Design::Variable < OO::Api::Base
  qualifiers :assembly, :platform

  def self.all(assembly, platform)
    if platform
      ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/variables")      
    else
      ok, data = request(:get, "assemblies/#{assembly}/design/variables")
    end
    return ok ? data.map {|e| new(assembly, platform, nil, e)} : []
  end

  def self.find(assembly, platform, variable)
    if platform
      ok, data = request(:get, "assemblies/#{assembly}/design/platforms/#{platform}/variables/#{variable}")   
    else
      ok, data = request(:get, "assemblies/#{assembly}/design/variables/#{variable}")
    end
    return nil unless ok
    variable = new(assembly, platform, data)
    return variable   
  end

  def save
    ci_id = data[:ciId]
    if platform
      ok = if ci_id.blank?
        self.class.request(:post, "assemblies/#{assembly}/design/platforms/#{platform}/variables", {:cms_dj_ci => data}, self)
      else
        self.class.request(:put, "assemblies/#{assembly}/design/platforms/#{platform}/variables/#{ci_id}", {:cms_dj_ci => data}, self)
      end
    else
      ok = if ci_id.blank?
        self.class.request(:post, "assemblies/#{assembly}/design/variables", {:cms_dj_ci => data}, self)
      else
        self.class.request(:put, "assemblies/#{assembly}/design/variables/#{ci_id}", {:cms_dj_ci => data}, self)
      end
    end
    return ok
  end

  def destroy
    ci_id = data[:ciId]
    if platform
      return self.class.request(:delete, "assemblies/#{assembly}/design/platforms/#{platform}/variables/#{ci_id}", '', self)
    else
      return self.class.request(:delete, "assemblies/#{assembly}/design/variables/#{ci_id}", '', self)
    end
  end
end
