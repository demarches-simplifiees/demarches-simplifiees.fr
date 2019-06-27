class ChampPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_a?(User)
        scope
          .joins(:dossier)
          .where({ dossiers: { user_id: user.id } })
      elsif user.is_a?(Gestionnaire)
        scope_with_join = scope.joins(dossier: :follows)
        scope_with_left_join = scope.left_joins(dossier: :follows)

        if user.user
          scope_with_left_join
            .where({ dossiers: { user_id: user.user.id } })
            .or(scope_with_left_join.where(dossiers: { follows: { gestionnaire_id: user.id } }))
        else
          scope_with_join.where(dossiers: { follows: { gestionnaire_id: user.id } })
        end
      else
        scope.none
      end
    end
  end
end
