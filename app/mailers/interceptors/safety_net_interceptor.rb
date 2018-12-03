# Prevent emails from being sent to addresses other than `*@beta.gouv.fr`.
class SafetyNetInterceptor
  class << self
    def delivering_email(message)
      message.to.each do |recipient|
        if !/@beta.gouv.fr$/.match(recipient)
          raise StandardError.new("Can’t send message to `#{recipient}`: it doesn’t match `*@beta.gouv.fr`")
        end
      end
    end
  end
end
