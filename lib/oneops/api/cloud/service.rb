class OO::Api::Cloud::Service < OO::Api::Base
  qualifiers :cloud, :source

  def self.all(cloud)
    ok, data = request(:get, "clouds/#{cloud}/services")
    return ok ? data.map {|e| new(cloud, nil, e)} : []
  end

  def self.find(cloud, service)
    ok, data = request(:get, "clouds/#{cloud}/services/#{service}")
    ok ? new(cloud, nil, data) : nil
  end

  def self.sources(cloud)
    ok, data = request(:get, "clouds/#{cloud}/services/available")
    ok ? data : nil
  end

  def self.build(cloud, source)
    ok, data = request(:get, "clouds/#{cloud}/services/new?mgmtCiId=#{source['ciId']}")
    ok ? new(cloud, source, data) : nil
  end

  def save
    ci_id = data[:ciId]
    ok = if ci_id.blank?
      self.class.request(:post, "clouds/#{cloud}/services", {:cms_ci => data, :mgmtCiId => source['ciId']}, self)
    else
      self.class.request(:put, "clouds/#{cloud}/services/#{ci_id}", {:cms_ci => data}, self)
    end
    return ok
  end

  def destroy
    return self.class.request(:delete, "clouds/#{cloud}/services/#{data[:ciId]}", '', self)
  end
end
