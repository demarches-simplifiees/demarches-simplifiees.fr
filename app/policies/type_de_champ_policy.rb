# frozen_string_literal: true

class TypeDeChampPolicy < ApplicationPolicy
  class Scope < ApplicationScope
    def resolve
      if administrateur.present?
        scope
          .joins(procedure: [:administrateurs])
          .where({ administrateurs: { id: administrateur.id } })
      else
        scope.none
      end
    end
  end
end
