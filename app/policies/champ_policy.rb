class ChampPolicy < ApplicationPolicy
  class Scope < ApplicationScope
    def resolve
      if user.blank?
        return scope.none
      end

      # Users can access public champs on their own dossiers.
      resolved_scope = scope
        .left_outer_joins(dossier: { groupe_instructeur: [:instructeurs] })
        .where('dossiers.user_id': user.id, private: false)

      if instructeur.present?
        # Additionnaly, instructeurs can access private champs
        # on dossiers they are allowed to instruct.
        instructeur_clause = scope
          .left_outer_joins(dossier: { groupe_instructeur: [:instructeurs] })
          .where('instructeurs.id': instructeur.id, private: true)
        resolved_scope = resolved_scope.or(instructeur_clause)
      end

      resolved_scope
    end
  end
end
