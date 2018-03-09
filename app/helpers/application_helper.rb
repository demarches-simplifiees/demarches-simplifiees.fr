module ApplicationHelper
  include SanitizeUrl

  def sanitize_url(url)
    if !url.nil?
      super(url, schemes: ['http', 'https'], replace_evil_with: root_url)
    end
  end

  def flash_class(level)
    case level
    when "notice" then "alert-success"
    when "alert" then "alert-danger"
    end
  end

  def current_email
    current_user.try(:email) ||
      current_gestionnaire.try(:email) ||
      current_administrateur.try(:email)
  end

  def root_path_for_profile(nav_bar_profile)
    case nav_bar_profile
    when :gestionnaire
      gestionnaire_procedures_path
    when :user
      users_dossiers_path
    else
      root_path
    end
  end
end
