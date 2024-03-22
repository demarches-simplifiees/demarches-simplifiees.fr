class GroupeGestionnaire::Card::ChildrenComponent < ApplicationComponent
  def initialize(groupe_gestionnaire:, path:)
    @groupe_gestionnaire = groupe_gestionnaire
    @path = path
  end
end
