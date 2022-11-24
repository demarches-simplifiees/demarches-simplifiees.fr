module Mutations
  class GroupeInstructeurModifier < Mutations::BaseMutation
    description "Modifier un groupe instructeur."

    argument :groupe_instructeur_id, ID, "Groupe instructeur ID", required: true, loads: Types::GroupeInstructeurType
    argument :label, String, "Libellé du groupe instructeur.", required: false
    argument :closed, Boolean, "L’état du groupe instructeur.", required: false

    field :groupe_instructeur, Types::GroupeInstructeurType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(groupe_instructeur:, label: nil, closed: nil)
      if groupe_instructeur.update({ label: label, closed: closed }.compact)
        { groupe_instructeur: groupe_instructeur }
      else
        { errors: groupe_instructeur.errors.full_messages }
      end
    end
  end
end
