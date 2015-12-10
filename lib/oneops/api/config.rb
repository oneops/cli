module OO
  module Api
    class Config
      class << self
        attr_accessor :organization, :site, :user, :password, :debug
      end
    end
  end
end
