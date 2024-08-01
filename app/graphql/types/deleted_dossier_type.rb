# frozen_string_literal: true

module Types
  class DeletedDossierType < Types::BaseObject
    description "Un dossier supprimé"

    global_id_field :id
    field :number, Int, "Le numéro du dossier qui a été supprimé.", null: false
    field :state, Types::DossierType::DossierState, "L’état du dossier supprimé.", null: false
    field :reason, String, "La raison de la suppression du dossier.", null: false

    field :date_supression, GraphQL::Types::ISO8601DateTime, "Date de suppression.", null: false

    def self.authorized?(object, context)
      context.authorized_demarche?(object.procedure)
    end

    def date_supression
      if object.is_a?(Dossier)
        object.hidden_by_administration_at || object.hidden_by_user_at
      else
        object.deleted_at
      end
    end

    def number
      if object.is_a?(Dossier)
        object.id
      else
        object.dossier_id
      end
    end

    def reason
      if object.is_a?(Dossier)
        object.hidden_by_reason
      else
        object.reason
      end
    end
  end
end
