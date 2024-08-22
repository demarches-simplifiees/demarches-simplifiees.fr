# frozen_string_literal: true

module Mutations
  class DemarcheCloner < Mutations::BaseMutation
    description "Cloner une démarche."

    argument :demarche, Types::DemarcheDescriptorType::FindDemarcheInput, "La démarche", required: true
    argument :title, String, "Le titre de la nouvelle démarche.", required: false

    field :demarche, Types::DemarcheDescriptorType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(demarche:, title: nil)
      demarche_number = demarche.number.presence || ApplicationRecord.id_from_typed_id(demarche.id)
      demarche = Procedure.find_by(id: demarche_number)

      if demarche.present? && (demarche.opendata? || context.authorized_demarche?(demarche))
        cloned_demarche = demarche.clone(context.current_administrateur, false)
        cloned_demarche.update!(libelle: title) if title.present?

        { demarche: cloned_demarche.draft_revision }
      else
        { errors: ["La démarche \"#{demarche_number}\" ne peut pas être clonée."] }
      end
    end
  end
end
