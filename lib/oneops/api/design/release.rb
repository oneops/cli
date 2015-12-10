class OO::Api::Design::Release < OO::Api::Base
  qualifiers :assembly

  def self.all(assembly)
    ok, data = request(:get, "assemblies/#{assembly}/design/releases")
    ok ? data.map {|e| new(assembly, e)} : []
  end

  def self.find(assembly, release)
    ok, data = request(:get, "assemblies/#{assembly}/design/releases/#{release}")
    ok ? new(assembly, data) : nil
  end

  def self.latest(assembly)
    ok, data = request(:get, "assemblies/#{assembly}/design/releases/latest")
    ok ? new(assembly, data) : nil
  end

  def commit(desc)
    self.class.request(:post, "assemblies/#{assembly}/design/releases/#{data[:releaseId]}/commit", {:desc => desc}, self)
  end

  def discard
    self.class.request(:post, "assemblies/#{assembly}/design/releases/#{data[:releaseId]}/discard", '', self)
  end
end
