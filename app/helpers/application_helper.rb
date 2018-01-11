module ApplicationHelper
  include SanitizeUrl

  def sanitize_url(url)
    super(url, schemes: ['http', 'https'], replace_evil_with: root_url)
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
end
