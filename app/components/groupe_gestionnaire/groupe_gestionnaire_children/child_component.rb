# frozen_string_literal: true

class GroupeGestionnaire::GroupeGestionnaireChildren::ChildComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(groupe_gestionnaire:, child:)
    @groupe_gestionnaire = groupe_gestionnaire
    @child = child
  end

  def name
    @child.name
  end

  def created_at
    try_format_datetime(@child.created_at)
  end
end
