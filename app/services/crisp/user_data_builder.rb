# frozen_string_literal: true

module Crisp
  class UserDataBuilder
    MAX_VALUE_LENGTH = 200

    def initialize(user)
      @user = user
      @instructeur = user.instructeur
      @administrateur = user.administrateur
    end

    def build_data
      data = {
        "Liens" => build_links,
        **build_notifications_data
      }

      truncate_values(data)
    end

    private

    attr_reader :user, :instructeur, :administrateur

    def build_links
      links = [user_link]
      links << instructeur_link if instructeur.present?
      links << administrateur_link if administrateur.present?
      links << email_link

      links.join("\n")
    end

    def build_notifications_data
      return {} if instructeur.blank?

      enabled_ids, disabled_ids = partition_procedure_notifications

      data = {}
      if enabled_ids.any?
        data["NotificationsActivees"] = "**Activées** sur démarche n° #{enabled_ids.map(&:to_s).join(", ")}"
      end

      if disabled_ids.any?
        data["NotificationsDesactivees"] = "**Désactivées** sur démarche n° #{disabled_ids.map(&:to_s).join(", ")}"
      end

      data
    end

    def partition_procedure_notifications
      enabled = []
      disabled = []

      return [enabled, disabled] if instructeur.blank?

      per_proc = instructeur.assign_to.group_by { it.groupe_instructeur.procedure_id }
      per_proc.each do |procedure_id, assign_tos|
        first_assign_to = assign_tos.first
        if notifications_disabled?(first_assign_to)
          disabled << procedure_id
        else
          enabled << procedure_id
        end
      end

      [enabled, disabled]
    end

    def notifications_disabled?(assign_to)
      !assign_to.instant_email_dossier_notifications_enabled ||
        !assign_to.instant_email_message_notifications_enabled ||
        !assign_to.instant_expert_avis_email_notifications_enabled
    end

    def user_link
      "[#{user.model_name.human}##{user.id}](#{manager_user_url})"
    end

    def instructeur_link
      "[#{instructeur.model_name.human}##{instructeur.id}](#{manager_instructeur_url})"
    end

    def administrateur_link
      "[#{administrateur.model_name.human}##{administrateur.id}](#{manager_administrateur_url})"
    end

    def email_link
      "[Emails##{user.id}](#{emails_manager_user_url})"
    end

    def manager_user_url
      Rails.application.routes.url_helpers.manager_user_url(user)
    end

    def manager_instructeur_url
      Rails.application.routes.url_helpers.manager_instructeur_url(instructeur)
    end

    def manager_administrateur_url
      Rails.application.routes.url_helpers.manager_administrateur_url(administrateur)
    end

    def emails_manager_user_url
      Rails.application.routes.url_helpers.emails_manager_user_url(user)
    end

    def truncate_values(data)
      data.transform_values { it.truncate(MAX_VALUE_LENGTH, omission: "…", separator: /\s+/) }
    end
  end
end
