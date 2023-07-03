module Mutations
  class GroupeInstructeurAjouterInstructeurs < Mutations::BaseMutation
    description "Ajouter des instructeurs à un groupe instructeur."

    argument :groupe_instructeur_id, ID, "Groupe instructeur ID.", required: true, loads: Types::GroupeInstructeurType
    argument :instructeurs, [Types::ProfileInput], "Instructeurs à ajouter.", required: true

    field :groupe_instructeur, Types::GroupeInstructeurType, null: true
    field :errors, [Types::ValidationErrorType], null: true
    field :warnings, [Types::WarningMessageType], null: true

    def resolve(groupe_instructeur:, instructeurs:)
      ids, emails = partition_instructeurs_by(instructeurs)
      instructeurs, invalid_emails = groupe_instructeur.add_instructeurs(ids:, emails:)

      instructeurs.each { groupe_instructeur.add(_1) }
      groupe_instructeur.reload

      result = { groupe_instructeur: }

      if invalid_emails.present?
        warning = I18n.t('administrateurs.groupe_instructeurs.add_instructeur.wrong_address',
          count: invalid_emails.size,
          emails: invalid_emails.join(', '))

        result[:warnings] = [warning]
      end

      if groupe_instructeur.procedure.routing_enabled? && instructeurs.present?
        GroupeInstructeurMailer
          .add_instructeurs(groupe_instructeur, instructeurs, current_administrateur.email)
          .deliver_later
      end

      result
    end
  end
end
