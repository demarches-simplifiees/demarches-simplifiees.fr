class ChampPolicy < ApplicationPolicy
  class Scope < ApplicationScope
    def resolve
      if user.present?
        scope
          .joins(:dossier)
          .where({ dossiers: { user_id: user.id } })
      else
        scope.none
      end
    end
  end
end
