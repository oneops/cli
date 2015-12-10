class OO::Api::Assembly < OO::Api::Base
  def self.all
    ok, data = request(:get, "assemblies")
    return ok ? data.map {|e| new(e)} : []
  end

  def self.find(assembly)
    ok, data = request(:get, "assemblies/#{assembly}")
    ok ? new(data) : nil
  end

  def save
    ci_id = data[:ciId]
    ok = if ci_id.blank?
      self.class.request(:post, "assemblies", {:cms_ci => self.data}, self)
    else
      self.class.request(:put, "assemblies/#{ci_id}", {:cms_ci => self.data}, self)
    end
    return ok
  end

  def destroy
    return self.class.request(:delete, "assemblies/#{data[:ciId]}", '', self)
  end

  def clone(name, description)
    export(name, description)
  end

  def catalog(name, description)
    export(name, description, 'catalog')
  end


  private

  def export(name, description, export = nil)
    ok, data = self.class.request(:post, "assemblies/#{self.data[:ciId]}/clone", {:ciName => name, :description => description, :export => export})
    if ok
      return export.blank? ? self.class.new(data) : OO::Api::Catalog.new(data)
    else
      self.errors = data
      return nil
    end
  end
end
