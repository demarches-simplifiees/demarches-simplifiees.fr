class TypeDeChampPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.is_a?(Administrateur)
        scope
          .joins(procedure: [:administrateurs])
          .where({ administrateurs: { id: user.id } })
      else
        scope.none
      end
    end
  end
end
