# frozen_string_literal: true

class MainNavigation::ExpertLinkComponent < ApplicationComponent
  def render?
    expert_signed_in?
  end


  def aria_current_for
    { current: current_page_in_scope? ? :page : nil }
  end

  private

  def current_page_in_scope?
    controller_path.split('/').include?('experts')
  end
end
