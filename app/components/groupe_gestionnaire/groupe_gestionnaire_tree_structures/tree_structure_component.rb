class GroupeGestionnaire::GroupeGestionnaireTreeStructures::TreeStructureComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(parent:, children:)
    @parent = parent
    @children = children
  end
end
