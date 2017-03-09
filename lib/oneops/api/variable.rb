class OO::Api::Variable < OO::Api::Base
  def as_pretty(options)
    if OO::Cli::Config.format.to_s == 'console'
      "#{ciName}=#{ciAttributes.secure == 'true' ? ciAttributes.encrypted_value : ciAttributes.value}"
    else
      super
    end
  end

  def set(value, opts = {})
    attrs = ciAttributes
    secure = opts[:secure]
    sticky = opts[:sticky]
    if secure && sticky
      attrs.secure_ = 'true'
      attrs.encrypted_value_ = value
    elsif secure && !sticky
      attrs.secure = 'true'
      attrs.encrypted_value = value
    elsif !secure && sticky
      attrs.secure_ = 'false'
      attrs.value_ = value
    else
      attrs.secure = 'false'
      attrs.value = value
    end
  end
end
