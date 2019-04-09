module ApplicationHelper
  include SanitizeUrl

  def sanitize_url(url)
    if !url.nil?
      super(url, schemes: ['http', 'https'], replace_evil_with: root_url)
    end
  end

  def flash_class(level, sticky: false, fixed: false)
    class_names = case level
    when 'notice'
      ['alert-success']
    when 'alert'
      ['alert-danger']
    end
    if sticky
      class_names << 'sticky'
    end
    if fixed
      class_names << 'alert-fixed'
    end
    class_names.join(' ')
  end

  def render_to_element(selector, partial:, outer: false, locals: {})
    method = outer ? 'outerHTML' : 'innerHTML'
    html = escape_javascript(render partial: partial, locals: locals)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').#{method} = \"#{html}\";")
    # rubocop:enable Rails/OutputSafety
  end

  def append_to_element(selector, partial:, locals: {})
    html = escape_javascript(render partial: partial, locals: locals)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').insertAdjacentHTML('beforeend', \"#{html}\");")
    # rubocop:enable Rails/OutputSafety
  end

  def render_flash(timeout: false, sticky: false, fixed: false)
    if flash.any?
      html = render_to_element('#flash_messages', partial: 'layouts/flash_messages', locals: { sticky: sticky, fixed: fixed }, outer: true)
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
    script << "if (el) { setTimeout(function() { #{method}; }, #{timeout}); }";
    script << "})();"
    # rubocop:disable Rails/OutputSafety
    raw(script);
    # rubocop:enable Rails/OutputSafety
  end

  def show_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').classList.remove('hidden');")
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

  def fire_event(event_name, data)
    # rubocop:disable Rails/OutputSafety
    raw("DS.fire('#{event_name}', #{raw(data)});")
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

    params = { tags: tags, type: type, dossier_id: dossier_id }.compact
    link_to title, contact_url(params), options
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
end
