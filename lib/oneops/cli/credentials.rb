module OO
  module Cli
    class Credentials
      class << self
        def read(site)
          netrc[site]
        end

        def write(site, credentials)
          FileUtils.mkdir_p(File.dirname(netrc_path))
          FileUtils.touch(netrc_path)
          FileUtils.chmod(0600, netrc_path) unless WINDOWS
          netrc[site] = credentials
          netrc.save
        end

        def delete(site)
          if netrc
            netrc.delete(site)
            netrc.save
          end
        end

        def netrc
          @netrc ||= begin
            Netrc.read(netrc_path)
          rescue => error
            if error.message =~ /^Permission bits for/
              perm = File.stat(netrc_path).mode & 0777
              abort("Permissions #{perm} for '#{netrc_path}' are too open. You should run `chmod 0600 #{netrc_path}` so that your credentials are NOT accessible by others.")
            else
              raise error
            end
          end
        end

        def netrc_path
          default = Netrc.default_path
          encrypted = "#{default}.gpg"
          File.exists?(encrypted) ? encrypted : default
        end
      end
    end
  end
end
