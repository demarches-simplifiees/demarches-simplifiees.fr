module TabsHelper
  def tab_item(label, url, active: false, badge: nil, notification: false, filter: nil)
    render partial: 'shared/tab_item', locals: {
      label: label,
      url: url,
      active: active,
      badge: badge,
      filter: filter,
      notification: notification
    }
  end

  def dynamic_tab_item(label, url_or_urls, badge: nil, notification: false)
    urls = [url_or_urls].flatten
    url = urls.first
    active = urls.any? { |u| current_page?(u) }

    tab_item(label, url, active: active, badge: badge, notification: notification)
  end

  def filter_tab_item(label, url, active: false, badge: nil, notification: false, filter: nil)
    badge_filter = badge_filter(badge, filter)
    tab_item(label, url, active: active, badge: badge_filter[:badge], notification: notification, filter: badge_filter[:filter])
  end

  def filter_count(total, filter)
    badge_filter = badge_filter(total, filter)
    render partial: 'shared/badge_filter', locals: { badge: badge_filter[:badge], filter: badge_filter[:filter] }
  end

  def badge_filter(badge, filter)
    return { badge: badge, filter: nil } if badge.eql? filter
    { badge: filter, filter: filter + " dossiers correspondants aux filters acturels.\n" + badge + " dossiers en tout." }
  end
end
