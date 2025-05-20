# frozen_string_literal: true

module Mutations
  class DemarcheAjouterAdministrateur < Mutations::BaseMutation
    description "Ajouter un administrateur a une démarche"

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "La démarche", required: true
    argument :administrateurs, [Types::ProfileInput], "Administrateur à ajouter.", required: true

    field :demarche, Types::DemarcheDescriptorType, null: true
    field :errors, [Types::ValidationErrorType], null: true
    field :warnings, [Types::WarningMessageType], null: true

    def resolve(demarche:, administrateurs:)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      demarche = Procedure.find_by(id: demarche_number)

      ids, emails = partition_administrators_by_profile_input(administrateurs)

      if context.authorized_demarche?(demarche)
        can_create_administrateur = allowed_to_create_administrateur?(ip: context.remote_ip)
        administrateurs_added, invalid_emails, not_found_email = demarche.add_administrateurs(ids:, emails:, can_create_administrateur:)

        if administrateurs_added.present?
          demarche.reload
        end

        warnings = []
        if invalid_emails.present?
          warnings.push I18n.t('administrateurs.procedures.add_administrateur.wrong_address',
                           count: invalid_emails.size,
                           emails: invalid_emails.join(', '))
        end
        if not_found_email.present?
          warnings.push I18n.t('administrateurs.procedures.add_administrateur.not_administrateur',
                         count: not_found_email.size,
                         emails: not_found_email.join(', '))
        end

        { demarche:, warnings: }
      else
        { errors: ["Vous n'avez pas le droit d'ajouter un administrateur sur la démarche"] }
      end
    end

    private

    def allowed_to_create_administrateur?(ip:)
      return false if ip.blank?
      whitelist = ENV.fetch('CREATE_ADMINISTRATEUR_BY_API_AUTHORIZED_NETWORKS', '').split(',')
        .map { begin IPAddr.new(_1) rescue nil end }
        .compact
      return false if whitelist.blank?
      whitelist.any? { |range| range.include?(ip) }
    end
  end
end
