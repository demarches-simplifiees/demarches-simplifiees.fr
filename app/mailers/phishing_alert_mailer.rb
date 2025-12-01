# frozen_string_literal: true

class PhishingAlertMailer < ApplicationMailer
  helper MailerHelper

  layout 'mailers/layout'

  def notify(user)
    @user = user
    @subject = "Détection d'une possible usurpation de votre compte"

    mail(to: user.email, subject: @subject)
  end

  def self.critical_email?(action_name) = false
end
