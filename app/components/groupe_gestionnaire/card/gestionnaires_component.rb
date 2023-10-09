class GroupeGestionnaire::Card::GestionnairesComponent < ApplicationComponent
  def initialize(groupe_gestionnaire:, path:)
    @groupe_gestionnaire = groupe_gestionnaire
    @path = path
  end
end
