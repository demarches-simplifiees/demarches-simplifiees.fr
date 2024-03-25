class GroupeGestionnaire::Card::CommentairesComponent < ApplicationComponent
  def initialize(groupe_gestionnaire:, administrateur:, path:)
    @groupe_gestionnaire = groupe_gestionnaire
    @administrateur = administrateur
    @path = path
  end
end
