# frozen_string_literal: true

class GroupeGestionnaire::Card::AdministrateursComponent < ApplicationComponent
  def initialize(groupe_gestionnaire:, path:, is_gestionnaire: true)
    @groupe_gestionnaire = groupe_gestionnaire
    @path = path
    @is_gestionnaire = is_gestionnaire
  end
end
