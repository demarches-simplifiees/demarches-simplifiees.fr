# frozen_string_literal: true

module MailerDefaultsConfigurableConcern
  extend ActiveSupport::Concern

  class_methods do
    # Save original defaults before they're modified
    def save_original_defaults
      @original_default_from ||= self.default[:from]
      @original_asset_host ||= asset_host
    end

    # Resets mailer settings to their original values
    def reset_original_defaults
      default from: original_default_from, reply_to: original_default_from
      default_url_options[:host] = ENV["APP_HOST"]
      Rails.application.routes.default_url_options[:host] = ENV["APP_HOST"]
      self.asset_host = original_asset_host
    end

    def original_default_from = @original_default_from
    def original_asset_host = @original_asset_host
  end

  included do
    before_action -> { self.class.save_original_defaults }
    before_action :set_currents_for_legacy
    after_action -> { self.class.reset_original_defaults }

    def configure_defaults_for_user(user, forced_domain = nil)
      return if !user.is_a?(User) # not for super-admins

      if user.preferred_domain_demarche_numerique_gouv_fr?
        set_currents_for_demarche_numerique_gouv_fr
      elsif forced_domain == ApplicationHelper::APP_HOST
        set_currents_for_demarche_numerique_gouv_fr
      elsif forced_domain == ApplicationHelper::APP_HOST_LEGACY
        set_currents_for_legacy
      else
        set_currents_for_legacy
      end

      # Define mailer defaults
      from = derive_from_header
      self.class.default from: from, reply_to: from
      self.class.default_url_options[:host] = Current.host
      Rails.application.routes.default_url_options[:host] = Current.host

      original_uri = URI.parse(self.class.original_asset_host) # in local with have http://, but https:// in production
      self.class.asset_host = "#{original_uri.scheme}://#{Current.host}"
    end

    def configure_defaults_for_email(email)
      user = User.find_by(email: email)
      configure_defaults_for_user(user)
    end

    private

    def set_currents_for_demarche_numerique_gouv_fr
      Current.application_name = "demarches.numerique.gouv.fr"
      Current.host = "demarches.numerique.gouv.fr"
      Current.contact_email = "contact@demarches.numerique.gouv.fr"
      Current.no_reply_email = NO_REPLY_EMAIL.sub("demarches-simplifiees.fr", "demarches.numerique.gouv.fr") # rubocop:disable DS/ApplicationName
    end

    def set_currents_for_legacy
      Current.application_name = APPLICATION_NAME
      Current.host = ENV["APP_HOST_LEGACY"] || ENV.fetch("APP_HOST") # APP_HOST_LEGACY is optional. Without it, we are in the situation withotu double domains
      Current.contact_email = CONTACT_EMAIL
      Current.no_reply_email = NO_REPLY_EMAIL
    end

    def derive_from_header
      if self.class.original_default_from.include?(NO_REPLY_EMAIL)
        Current.no_reply_email
      else
        "#{Current.application_name} <#{Current.contact_email}>"
      end
    end
  end
end
