class OO::Api::Design::Design < OO::Api::Base
  qualifiers :assembly

  def extract(format = 'yaml')
    ok, data = self.class.request(:get, "assemblies/#{assembly}/design/extract.#{format}")
    ok ? data : nil
  end

  def load(data)
    ok, data = self.class.request(:put, "assemblies/#{assembly}/design/load", {:data => data}, self)
    ok
  end
end
