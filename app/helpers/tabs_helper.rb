# frozen_string_literal: true

module TabsHelper
  def tab_i18n_key_from_status(status)
    case status
    when 'a-suivre'
      'views.instructeurs.dossiers.tab_steps.to_follow' # i18n-tasks-use t('views.instructeurs.dossiers.tab_steps.to_follow')
    when 'suivis'
      'pluralize.followed'
    when 'traites'
      'pluralize.processed'
    when 'tous'
      'views.instructeurs.dossiers.tab_steps.total' # i18n-tasks-use t('views.instructeurs.dossiers.tab_steps.total')
    when 'supprimes'
      'instructeurs.dossiers.labels.dossiers_supprimes'
    when 'expirant'
      'pluralize.dossiers_close_to_expiration'
    when 'archives'
      'pluralize.archived'
    else
      fail ArgumentError, "Unknown tab status: #{status}"
    end
  end

  def tab_item(label, url, active: false, badge: nil, notification: false, icon: nil)
    render partial: 'shared/tab_item', locals: {
      label: label,
      url: url,
      active: active,
      badge: badge,
      notification: notification,
      icon: icon
    }
  end

  def dynamic_tab_item(label, url_or_urls, badge: nil, notification: false, icon: nil)
    urls = [url_or_urls].flatten
    url = urls.first
    active = urls.any? { |u| current_page?(u) }

    tab_item(label, url, active: active, badge: badge, notification: notification, icon: icon)
  end
end
