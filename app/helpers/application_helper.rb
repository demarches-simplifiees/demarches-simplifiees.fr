module ApplicationHelper
  include SanitizeUrl

  def html_lang
    I18n.locale.to_s
  end

  def active_locale_link(locale)
    link_to save_locale_path(locale:), {
      method: :post,
      class: "fr-translate__language fr-nav__link",
      hreflang: locale,
      lang: locale,
      "aria-current": I18n.locale == locale ? "true" : nil
    }.compact do
      yield
    end
  end

  def sanitize_url(url)
    if !url.nil?
      super(url, schemes: ['http', 'https'], replace_evil_with: root_url)
    end
  end

  def flash_class(level, sticky: false, fixed: false)
    class_names = []

    case level
    when 'notice'
      class_names << 'alert-success'
    when 'alert', 'error'
      class_names << 'alert-danger'
    end

    if sticky
      class_names << 'sticky'
    end
    if fixed
      class_names << 'alert-fixed'
    end
    class_names.join(' ')
  end

  def flash_role(level)
    return "status" if level == "notice"

    'alert'
  end

  def react_component(name, props = {}, html = {})
    tag.div(**html.merge(data: { controller: 'react', react_component_value: name, react_props_value: props.to_json }))
  end

  def current_email
    current_user&.email ||
      current_instructeur&.email ||
      current_administrateur&.email
  end

  def staging?
    Rails.application.config.ds_env == 'staging'
  end

  def contact_link(title, options = {})
    tags, type, dossier_id = options.values_at(:tags, :type, :dossier_id)
    options.except!(:tags, :type, :dossier_id)

    params = { tags: tags, type: type, dossier_id: dossier_id }.compact
    link_to title, contact_url(params), options
  end

  def root_path_for_profile(nav_bar_profile)
    case nav_bar_profile
    when :instructeur
      instructeur_procedures_path
    when :user
      dossiers_path
    else
      root_path
    end
  end

  def root_path_info_for_profile(nav_bar_profile)
    case nav_bar_profile
    when :administrateur
      [admin_procedures_path, t("admin", scope: "layouts.root_path_link_title")]
    when :instructeur
      [instructeur_procedures_path, t("instructeur", scope: "layouts.root_path_link_title")]
    when :user
      [dossiers_path, t("user", scope: "layouts.root_path_link_title")]
    else
      [root_path, t("default", scope: "layouts.root_path_link_title")]
    end
  end

  def try_format_date(date)
    date.present? ? I18n.l(date, format: :long) : ''
  end

  def try_format_datetime(datetime)
    datetime.present? ? I18n.l(datetime) : ''
  end

  def try_format_mois_effectif(etablissement)
    if etablissement.entreprise_effectif_mois.present? && etablissement.entreprise_effectif_annee.present?
      [etablissement.entreprise_effectif_mois, etablissement.entreprise_effectif_annee].join('/')
    else
      ''
    end
  end

  def dismiss_outdated_browser_banner
    cookies[:dismissed_outdated_browser_banner] = {
      value: 'true',
      expires: 1.week.from_now
    }
  end

  def has_dismissed_outdated_browser_banner?
    cookies[:dismissed_outdated_browser_banner] == 'true'
  end

  def supported_browser?
    BrowserSupport.supported?(browser)
  end

  def show_outdated_browser_banner?
    !supported_browser? && !has_dismissed_outdated_browser_banner?
  end

  def vite_legacy?
    if ENV['VITE_LEGACY'] == 'disabled'
      false
    else
      Rails.env.production? || ENV['VITE_LEGACY'] == 'enabled'
    end
  end

  def external_link_attributes
    { target: "_blank", rel: "noopener noreferrer" }
  end

  def new_tab_suffix(title)
    "#{title} — #{t('utils.new_tab')}"
  end

  def download_details(attachment)
    "#{attachment.filename.extension.upcase} – #{number_to_human_size(attachment.byte_size)}"
  end
end
