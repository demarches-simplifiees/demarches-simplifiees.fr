# frozen_string_literal: true

ActiveSupport.on_load(:action_mailer) do
  require "dolist/api_sender"

  ActionMailer::Base.add_delivery_method :dolist_api, Dolist::APISender
end
