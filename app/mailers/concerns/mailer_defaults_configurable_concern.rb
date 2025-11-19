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
    # YOLO, envoie tous les liens vers le nouveau domaine
    before_action :set_currents_for_demarche_numerique_gouv_fr
    after_action -> { self.class.reset_original_defaults }

    def configure_defaults_for_user(_user, _forced_domain = nil)
      # Define mailer defaults
      from = derive_from_header
      self.class.default from: from, reply_to: from
      self.class.default_url_options[:host] = Current.host
      Rails.application.routes.default_url_options[:host] = Current.host

      original_uri = URI.parse(self.class.original_asset_host) # in local with have http://, but https:// in production
      self.class.asset_host = "#{original_uri.scheme}://#{Current.host}"
    end

    def configure_defaults_for_email(_email)
      configure_defaults_for_user(nil)
    end

    private

    def set_currents_for_demarche_numerique_gouv_fr
      Current.application_name = "demarche.numerique.gouv.fr"
      Current.host = ENV["APP_HOST"]
      Current.contact_email = "contact@demarche.numerique.gouv.fr"
      Current.no_reply_email = "Démarche Numérique <ne-pas-repondre@demarche.numerique.gouv.fr>"
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
