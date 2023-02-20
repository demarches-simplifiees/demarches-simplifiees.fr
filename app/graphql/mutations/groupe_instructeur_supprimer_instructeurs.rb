module Mutations
  class GroupeInstructeurSupprimerInstructeurs < Mutations::BaseMutation
    description "Supprimer des instructeurs d’un groupe instructeur."

    argument :groupe_instructeur_id, ID, "Groupe instructeur ID.", required: true, loads: Types::GroupeInstructeurType
    argument :instructeurs, [Types::ProfileInput], "Instructeurs à supprimer.", required: true

    field :groupe_instructeur, Types::GroupeInstructeurType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(groupe_instructeur:, instructeurs:)
      ids, emails = partition_instructeurs_by(instructeurs)
      instructeurs = groupe_instructeur.instructeurs.find_all_by_identifier(ids:, emails:)

      instructeurs.each { groupe_instructeur.remove(_1) }
      groupe_instructeur.reload

      if instructeurs.present?
        GroupeInstructeurMailer
          .notify_group_when_instructeurs_removed(groupe_instructeur, instructeurs, current_administrateur.email)
          .deliver_later
      end

      { groupe_instructeur: }
    end
  end
end
