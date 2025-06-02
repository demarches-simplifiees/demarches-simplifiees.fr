# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include MailerDefaultsConfigurableConcern
  include MailerDolistConcern
  include MailerMonitoringConcern
  include BalancedDeliveryConcern
  include PriorityDeliveryConcern

  helper :application # gives access to all helpers defined within `application_helper`.
  default from: "#{Current.application_name} <#{CONTACT_EMAIL}>"
  layout 'mailer'

  before_action -> { Sentry.set_tags(mailer: mailer_name, action: action_name) }
end
