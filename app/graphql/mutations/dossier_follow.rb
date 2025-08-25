# frozen_string_literal: true

module Mutations
  class DossierFollow < BaseMutation
    include DossierHelper

    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur ID", required: true, loads: Types::ProfileType
    argument :follow, Boolean, "Foolow ou non", default_value: true

    field :dossier, Types::DossierType, null: true
    field :instructeur, Types::ProfileType, null: false
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, instructeur:, follow:)
      if follow
        instructeur.follow(dossier)
      else
        instructeur.unfollow(dossier)
      end

      { dossier:, instructeur: }
    end

    def authorized?(dossier:, instructeur:, **args)
      dossier_authorized_for?(dossier, instructeur)
    end
  end
end
