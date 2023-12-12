# frozen_string_literal: true

class MainNavigation::UsagerLinkComponent < ApplicationComponent
  def usager?
    helpers.user_signed_in?
  end

  def aria_current_for
    { current: current_page_in_scope? ? :page : nil }
  end

  private

  def current_page_in_scope?
    controller_path.split('/').include?('users')
  end
end
