# frozen_string_literal: true

class MainNavigation::InstructeurExpertNavigationComponent < ApplicationComponent
  def instructeur?
    helpers.instructeur_signed_in?
  end

  def expert?
    helpers.expert_signed_in?
  end

  def aria_current_for(page)
    { current: page == current_page ? true : nil }
  end

  private

  def current_page
    case controller_name
    when 'avis'
      :avis
    when 'procedures', 'dossiers'
      :procedure
    end
  end
end
