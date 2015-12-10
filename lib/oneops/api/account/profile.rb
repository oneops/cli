class OO::Api::Account::Profile < OO::Api::Base
  def self.authentication_token
    ok, data = request(:post, "account/profile/authentication_token", {:user => {:username => OO::Api::Config.user, :password => OO::Api::Config.password}})
    ok ? data['token'] : nil
  end

  def self.find
    ok, data = request(:get, "account/profile")
    ok ? new(data) : nil
  end

  def change_organization(org_id)
    return self.class.request(:put, "account/profile/change_organization", {:org_id => org_id}, self)
  end

  protected

  def self.prefix
    false
  end
end
