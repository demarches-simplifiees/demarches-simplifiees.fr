require Rails.root.join('app', 'mailers', 'interceptors', 'safety_net_interceptor')

if ENV['MAIL_SAFETY_NET'] == 'enabled'
  ActionMailer::Base.register_interceptor(SafetyNetInterceptor)
end
