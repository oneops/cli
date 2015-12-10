class OO::Api::Cloud::Cloud < OO::Api::Base
  def self.all
    ok, data = request(:get, 'clouds')
    return ok ? data.map {|e| new(e)} : []
  end

  def self.find(cloud)
    ok, data = request(:get, "clouds/#{cloud}")
    ok ? new(data) : nil
  end

  def self.locations
    ok, data = request(:get, 'clouds/locations')
    ok ? data : nil
  end

  def save
    ci_id = data[:ciId]
    ok = if ci_id.blank?
      self.class.request(:post, 'clouds', {:cms_ci => self.data}, self)
    else
      self.class.request(:put, "clouds/#{ci_id}", {:cms_ci => self.data}, self)
    end
    return ok
  end

  def destroy
    return self.class.request(:delete, "clouds/#{data[:ciId]}", '', self)
  end
end
