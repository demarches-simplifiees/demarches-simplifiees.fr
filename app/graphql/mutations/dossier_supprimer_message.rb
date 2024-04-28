# frozen_string_literal: true

module Mutations
  class DossierSupprimerMessage < Mutations::BaseMutation
    description "Supprimer un message."

    argument :message_id, ID, required: true, loads: Types::MessageType
    argument :instructeur_id, ID, required: true, loads: Types::ProfileType

    field :message, Types::MessageType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(message:, **args)
      message.soft_delete!

      { message: }
    end

    def authorized?(message:, instructeur:, **args)
      if !message.soft_deletable?(instructeur)
        return false, { errors: ["Le message ne peut pas être supprimé"] }
      end
      dossier_authorized_for?(message.dossier, instructeur)
    end
  end
end
