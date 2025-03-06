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
        administrateurs_added, invalid_emails = demarche.add_administrateurs(ids:, emails:)

        if administrateurs_added.present?
          demarche.reload
        end

        result = { demarche: }

        if invalid_emails.present?
          warning = I18n.t('administrateurs.procedures.add_administrateur.wrong_address',
                           count: invalid_emails.size,
                           emails: invalid_emails.join(', '))
          result[:warnings] = [warning]
        end

        result
      else
        { errors: ["Vous n'avez pas le droit d'ajouter un administrateur sur la démarche"] }
      end
    end
  end
end
