class OO::Api::Pack < OO::Api::Base
  qualifiers :source
  def self.all
    ok, data = request(:get, 'catalog/packs')
    return ok ? data.map {|source, pack| new(source, pack)} : []
  end
end
