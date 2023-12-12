# frozen_string_literal: true

class MainNavigation::AdministrateurLinkComponent < ApplicationComponent
  def render?
    administrateur_signed_in?
  end

  def aria_current_for(scope)
    { current: current_page_in_scope?(scope) ? :page : nil }
  end

  def current_page_in_scope?(scope)
    is_on_all_procedures_page = current_page?(all_admin_procedures_path)
    return false if is_on_all_procedures_page && scope == :root
    return true if scope == :root && controller_path.split('/').include?('administrateurs')
    return true if is_on_all_procedures_page
    return false
  end
end
