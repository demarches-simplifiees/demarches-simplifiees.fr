# frozen_string_literal: true

class  MainNavigation::GestionnaireLinkComponent < ApplicationComponent
  def render?
    gestionnaire_signed_in?
  end


  def aria_current_for(page)
    { current: page == current_page ? :page : nil }
  end
end
