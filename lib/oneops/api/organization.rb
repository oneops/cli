class OO::Api::Organization < OO::Api::Base
  
  def self.find
    ok, data = request(:get, "organization")
    ok ? new(data) : nil
  end
  
  def self.health
    ok, data = request(:get, "operations/health")
    return ok ? data : []
  end

end
