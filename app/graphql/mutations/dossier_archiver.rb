module Mutations
  class DossierArchiver < Mutations::BaseMutation
    description "Archiver le dossier."

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur qui prend la décision sur le dossier.", required: true, loads: Types::ProfileType

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, instructeur:)
      if dossier.termine?
        dossier.archiver!(instructeur)

        { dossier: dossier }
      else
        { errors: ["Un dossier ne peut être archivé qu’une fois le traitement terminé"] }
      end
    end

    def authorized?(dossier:, instructeur:)
      instructeur.is_a?(Instructeur) && instructeur.dossiers.exists?(id: dossier.id)
    end
  end
end
