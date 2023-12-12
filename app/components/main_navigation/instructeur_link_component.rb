# frozen_string_literal: true

class MainNavigation::InstructeurLinkComponent < ApplicationComponent
  def render?
    instructeur_signed_in?
  end

  def aria_current_for
    { current: current_page_in_scope? ? :page : nil }
  end

  private

  def current_page_in_scope?
    controller_path.split('/').include?('instructeurs')
  end
end
