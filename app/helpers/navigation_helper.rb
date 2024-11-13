# frozen_string_literal: true

module NavigationHelper
  def current_nav_section
    if procedure_management_section?
      'procedure_management'
    elsif user_support_section?
      'user_support'
    elsif downloads_section?
      'downloads'
    else
      'follow_up'
    end
  end

  private

  def procedure_management_section?
    return true if params[:action].in?(['administrateurs', 'stats', 'email_notifications', 'deleted_dossiers'])
    return true if params[:controller] == 'instructeurs/groupe_instructeurs'

    false
  end

  def user_support_section?
    params[:action] == 'email_usagers' || params[:action] == 'apercu'
  end

  def downloads_section?
    params[:action] == 'exports' ||
    params[:controller] == 'instructeurs/archives'
  end
end
