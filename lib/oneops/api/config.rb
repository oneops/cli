module OO
  module Api
    class Config
      class << self
        attr_accessor :organization, :site, :user, :password, :debug, :verify_ssl, :timeout
      end
      verify_ssl = true
    end
  end
end
