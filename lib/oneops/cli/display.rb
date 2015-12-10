module VMCExtensions
  def say(message)
    OO::Cli::Config.output.puts(message) if OO::Cli::Config.output
  end

  alias :display :say

  def blurt(message)
    OO::Cli::Config.output.print(message) if OO::Cli::Config.output
  end

  def ask
    $stdin.gets.to_s.strip
  end

  def ask!
    password = ''
    if WINDOWS
      while char = Win32API.new('crtdll', '_getch', [], 'L').Call do
        break if char == 10 || char == 13   # received carriage return or newline
        if char == 127 || char == 8   # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end
      puts
    else
      with_tty { system 'stty -echo' }
      password = ask
      puts
      with_tty { system 'stty echo' }
    end
    return password
  end

  def with_tty(&block)
    return unless $stdin.isatty
    begin
      yield
    rescue
      # fails on windows
    end
  end
end

module OOStringExtensions
  def lpad(length, char = ' ')
    diff = length - self.length
    diff > 0 ? "#{char * diff}#{self}" : self
  end

  def rpad(length, char = ' ')
    diff = length - self.length
    diff > 0 ? "#{self}#{char * diff}" : self
  end

  def trunc(length, delimeter = '...')
    return self if self.length <= length
    "#{self[0...(length - delimeter.length)]}#{delimeter}"
  end

  def red
    colorize("\e[0m\e[31m")
  end

  def green
    colorize("\e[0m\e[32m")
  end

  def yellow
    colorize("\e[0m\e[33m")
  end

  def blue
    colorize("\e[0m\e[34m")
  end

  def magenta
    colorize("\e[0m\e[35m")
  end

  def cyan
    colorize("\e[0m\e[36m")
  end

  def colorize(color_code)
    if OO::Cli::Config.colorize
      "#{color_code}#{self}\e[0m"
    else
      self
    end
  end
end

class Object
  include VMCExtensions

  def to_pretty(options = {})
    as_pretty(options).send("to_#{OO::Cli::Config.format.presence || 'console'}", options)
  end

  def as_pretty(options)
    self.class == Hash ? self : JSON.parse(self.to_json)
  end
end

class Hash
  def to_console(options = {})
    self.sort.map do |k,v|
      if k == 'created' or k == 'updated'
        "#{k.green} #{Time.at(v/1000).utc.to_s}"
      elsif v.class == Hash or v.class == Array
        "#{k.green} #{v.to_yaml.lpad(2)}"
      else
        "#{k.green} #{v.to_s}"
      end
    end
  end
end

class Array
  def to_console(options = {})
    return self.map { |r| r['ciName'] }
  end

  def as_pretty(options)
    map { |e| e.as_pretty(options) }
  end
end

class String
  include OOStringExtensions
end
