module OO::Cli
  class Command::Design::Attachment < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |p| Config.set_in_place(:platform, p)}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
        opts.on('-m', '--attachment ATTACHMENT', 'Attachment name') { |m| Config.set_in_place(:attachment, m)}
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops design attachment

   Management of component attachments in design.

#{options_help}

Available actions:

    design attachment list   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>
    design attachment show   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -m <ATTACHMENT>
    design attachment open   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -m <ATTACHMENT>
    design attachment create -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -m <ATTACHMENT> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]]
    design attachment update -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -m <ATTACHMENT> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]]
    design attachment delete -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -m <ATTACHMENT>

Available attributes:
    basic_auth_user
    basic_auth_password
    checksum
    content
    exec_cmd
    headers
    path
    priority
    run_on
    source

Note:
    Use '_' suffix for to lock attribute value ("sticky" assignment).  For example, here is "lock" assignment:
       oneops transition -a ASSEMBLY variable update some-var_=whatever

    and this one is not:
       oneops transition -a ASSEMBLY variable update some-var=whatever
COMMAND_HELP
    end

    def validate(action, *args)
      unless Config.platform.present?
        say 'Please specify platform!'.red
        return false
      end

      unless Config.component.present?
        say 'Please specify component!'.red
        return false
      end

      unless action == :default || action == :list || Config.attachment.present?
        say 'Please specify attachment!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.attachment.present? ? show(*args) : list(*args)
    end

    def list(*args)
      attachments = OO::Api::Design::Attachment.all(Config.assembly, Config.platform, Config.component)
      say attachments.to_pretty
    end

    def show(*args)
      attachment = OO::Api::Design::Attachment.find(Config.assembly, Config.platform, Config.component, Config.attachment)
      say attachment.to_pretty
    end

    def open(*args)
      attachment = OO::Api::Design::Attachment.find(Config.assembly, Config.platform, Config.component, Config.attachment)
      open_ci(attachment.ciId)
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=', 2)
        attrs[attr] = value if attr && value
        attrs
      end
      attachment = OO::Api::Design::Attachment.build(Config.assembly, Config.platform, Config.component)
      attachment.ciName = Config.attachment
      attachment.ciAttributes.merge!(attributes)
      if attachment.save
        say attachment.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{attachment.errors.join("\n   ")}"
      end

    end

    def update(*args)
      attachment = OO::Api::Design::Attachment.find(Config.assembly, Config.platform, Config.component, Config.attachment)
      args.each do |a|
        attr, value = a.split('=', 2)
        attachment.ciAttributes[attr] = value if attr && value
      end
      if attachment.save
        say attachment.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{attachment.errors.join("\n   ")}"
      end
    end

    def delete(*args)
      attachment = OO::Api::Design::Attachment.find(Config.assembly, Config.platform, Config.component, Config.attachment)
      say "#{'Failed:'.yellow}\n   #{attachment.errors.join("\n   ")}" unless attachment.destroy
    end
  end
end
