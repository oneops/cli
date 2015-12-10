class OO::Api::Account::Organization < OO::Api::Base
  def self.all
    ok, data = request(:get, 'account/organizations')
    return ok ? data.map {|e| new(e)} : []
  end

  def create
    return self.class.request(:post, 'account/organizations', {:name => self.data[:name]}, self)
  end

  def delete
    return self.class.request(:delete, "account/organizations/#{self.data[:id]}", '', self)
  end

  def leave
    return self.class.request(:delete, "account/organizations/#{self.data[:id]}/leave", '', self)
  end
  
  protected
  
  def self.prefix
    false
  end
end
