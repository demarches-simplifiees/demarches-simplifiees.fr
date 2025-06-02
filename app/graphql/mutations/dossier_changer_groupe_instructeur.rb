# frozen_string_literal: true

module Mutations
  class DossierChangerGroupeInstructeur < Mutations::BaseMutation
    include DossierHelper

    description "Changer le grope instructeur du dossier."

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :groupe_instructeur_id, ID, "Group instructeur a affecter", required: true, loads: Types::GroupeInstructeurType

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, groupe_instructeur:)
      dossier.assign_to_groupe_instructeur(groupe_instructeur, DossierAssignment.modes.fetch(:manual), current_administrateur)

      { dossier: }
    end

    def authorized?(dossier:, groupe_instructeur:)
      if dossier.groupe_instructeur == groupe_instructeur
        return false, { errors: ["Le dossier est déjà avec le grope instructeur: '#{groupe_instructeur.label}'"] }
      elsif dossier.procedure != groupe_instructeur.procedure
        return false, { errors: ["Le groupe instructeur '#{groupe_instructeur.label}' n’appartient pas à la même démarche que le dossier"] }
      else
        true
      end
    end
  end
end
