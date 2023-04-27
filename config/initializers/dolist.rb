ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.add_delivery_method :dolist_api, Dolist::APISender
end
