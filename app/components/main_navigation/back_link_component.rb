# frozen_string_literal: true

class MainNavigation::BackLinkComponent < ApplicationComponent
  def render?
    controller_path == 'users/commencer'
  end
end

