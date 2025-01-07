# frozen_string_literal: true

module TabsHelper
  def i18n_tab_from_status(status, count: nil)
    case status
    when 'a-suivre'
      t('instructeurs.dossiers.labels.to_follow', count:)
    when 'suivis'
      t('pluralize.followed', count:)
    when 'traites'
      t('pluralize.processed', count:)
    when 'tous'
      t('instructeurs.dossiers.labels.total')
    when 'supprimes'
      t('instructeurs.dossiers.labels.trash')
    when 'expirant'
      t('pluralize.dossiers_close_to_expiration', count:)
    when 'archives'
      t('instructeurs.dossiers.labels.to_archive')
    else
      fail ArgumentError, "Unknown tab status: #{status}"
    end
  end

  def tab_item(label, url, active: false, badge: nil, notification: false, html_class: nil)
    render partial: 'shared/tab_item', locals: {
      label: label,
      url: url,
      active: active,
      badge: badge,
      notification: notification,
      html_class: html_class
    }
  end

  def dynamic_tab_item(label, url_or_urls, badge: nil, notification: false)
    urls = [url_or_urls].flatten
    url = urls.first
    active = urls.any? { |u| current_page?(u) }

    tab_item(label, url, active: active, badge: badge, notification: notification)
  end
end
