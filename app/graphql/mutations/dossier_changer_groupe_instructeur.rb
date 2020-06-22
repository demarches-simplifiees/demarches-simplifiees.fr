module Mutations
  class DossierChangerGroupeInstructeur < Mutations::BaseMutation
    include DossierHelper

    description "Changer le grope instructeur du dossier."

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :groupe_instructeur_id, ID, "Group instructeur a affecter", required: true, loads: Types::GroupeInstructeurType

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, groupe_instructeur:)
      if dossier.groupe_instructeur == groupe_instructeur
        { errors: ["Le dossier est déjà avec le grope instructeur: '#{groupe_instructeur.label}'"] }
      else
        dossier.update!(groupe_instructeur: groupe_instructeur)
        { dossier: dossier }
      end
    end

    def authorized?(dossier:, groupe_instructeur:)
      dossier.groupe_instructeur.procedure == groupe_instructeur.procedure
    end
  end
end
