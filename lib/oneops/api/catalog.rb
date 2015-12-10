class OO::Api::Catalog < OO::Api::Base
  def self.all
    ok, data = request(:get, 'catalogs')
    return ok ? data.map {|e| new(e)} : []
  end

  def self.find(catalog, type = nil)
    type ||= ''
    ok, data = request(:get, "catalogs/#{catalog}#{'?public=true' if type.downcase == 'public'}#{'?private=true' if type.downcase == 'private'}")
    ok ? new(data) : nil
  end

  def destroy
    return self.class.request(:delete, "catalogs/#{data[:ciId]}", '', self)
  end
end
