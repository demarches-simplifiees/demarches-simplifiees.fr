module TabsHelper
  def tab_item(label, url, active: false, badge: nil, notification: false)
    render partial: 'shared/tab_item', locals: {
      label: label,
      url: url,
      active: active,
      badge: badge,
      notification: notification
    }
  end

  def dynamic_tab_item(label, url, badge: nil, notification: false)
    tab_item(label, url, active: current_page?(url), badge: badge, notification: notification)
  end
end
