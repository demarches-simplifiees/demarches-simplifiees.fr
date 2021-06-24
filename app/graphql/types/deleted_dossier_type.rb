module Types
  class DeletedDossierType < Types::BaseObject
    description "Un dossier supprimé"

    global_id_field :id
    field :number, Int, "Le numéro du dossier qui a été supprimé.", null: false, method: :dossier_id
    field :state, Types::DossierType::DossierState, "L’état du dossier supprimé.", null: false
    field :reason, String, "La raison de la suppression du dossier.", null: false

    field :date_supression, GraphQL::Types::ISO8601DateTime, "Date de suppression.", null: false, method: :deleted_at

    def self.authorized?(object, context)
      context.authorized_demarche?(object.procedure)
    end
  end
end
