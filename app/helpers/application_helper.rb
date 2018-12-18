module ApplicationHelper
  include SanitizeUrl

  def sanitize_url(url)
    if !url.nil?
      super(url, schemes: ['http', 'https'], replace_evil_with: root_url)
    end
  end

  def flash_class(level, sticky = false)
    case level
    when "notice" then "alert-success#{sticky ? ' sticky' : ''}"
    when "alert" then "alert-danger#{sticky ? ' sticky' : ''}"
    end
  end

  def render_to_element(selector, partial:, outer: false, locals: {})
    method = outer ? 'outerHTML' : 'innerHTML'
    html = escape_javascript(render partial: partial, locals: locals)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').#{method} = \"#{html}\";")
    # rubocop:enable Rails/OutputSafety
  end

  def render_flash(timeout: false, sticky: false)
    if flash.any?
      html = render_to_element('#flash_messages', partial: 'layouts/flash_messages', locals: { sticky: sticky }, outer: true)
      flash.clear
      if timeout
        html += remove_element('#flash_messages', timeout: timeout, inner: true)
      end
      html
    end
  end

  def remove_element(selector, timeout: 0, inner: false)
    script = "(function() {";
    script << "var el = document.querySelector('#{selector}');"
    method = (inner ? "el.innerHTML = ''" : "el.parentNode.removeChild(el)")
    script << "setTimeout(function() { #{method}; }, #{timeout});";
    script << "})();"
    # rubocop:disable Rails/OutputSafety
    raw(script);
    # rubocop:enable Rails/OutputSafety
  end

  def disable_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').disabled = true;")
    # rubocop:enable Rails/OutputSafety
  end

  def enable_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').disabled = false;")
    # rubocop:enable Rails/OutputSafety
  end

  def current_email
    current_user&.email ||
      current_gestionnaire&.email ||
      current_administrateur&.email
  end

  def staging?
    ENV['APP_NAME'] == 'tps_dev'
  end

  def contact_link(title, options = {})
    tags, type, dossier_id = options.values_at(:tags, :type, :dossier_id)
    options.except!(:tags, :type, :dossier_id)

    if Flipflop.support_form?
      params = { tags: tags, type: type, dossier_id: dossier_id }.compact
      link_to title, contact_url(params), options
    else
      mail_to CONTACT_EMAIL, title,
        options.merge(subject: "Question à propos de demarches-simplifiees.fr")
    end
  end

  def root_path_for_profile(nav_bar_profile)
    case nav_bar_profile
    when :gestionnaire
      gestionnaire_procedures_path
    when :user
      dossiers_path
    else
      root_path
    end
  end

  def sentry_config
    sentry = Rails.application.secrets.sentry
    if sentry
      {
        dsn: sentry[:browser],
        id: current_user&.id,
        email: current_email
      }.to_json
    else
      {}
    end
  end
end
