# frozen_string_literal: true

module Mutations
  class DemarcheSupprimerAdministrateur < Mutations::BaseMutation
    description "Supprimer un administrateur d'une démarche"

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "La démarche", required: true
    argument :administrateurs, [Types::ProfileInput], "Administrateur à retirer.", required: true

    field :demarche, Types::DemarcheDescriptorType, null: true
    field :errors, [Types::ValidationErrorType], null: true
    field :warnings, [Types::WarningMessageType], null: true

    def resolve(demarche:, administrateurs:)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      demarche = Procedure.find_by(id: demarche_number)
      ids, emails = partition_administrators_by_profile_input(administrateurs)

      if context.authorized_demarche?(demarche)
        administrateurs = demarche.administrateurs.find_all_by_identifier(ids:, emails:)

        if administrateurs.present?
          administrateurs.each { demarche.administrateurs.delete(_1) }
          demarche.reload
        end
        { demarche: }
      else
        { errors: ["Vous n'avez pas le droit de retirer un administrateur sur la démarche"] }
      end
    end
  end
end
