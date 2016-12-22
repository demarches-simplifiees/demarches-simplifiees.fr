class NotificationService

  def initialize type_notif, dossier_id
    @type_notif = type_notif
    @dossier_id = dossier_id

    notification.liste.push text_for_notif

    self
  end

  def notify
    notification.save
  end

  def notification
    @notification ||=
        begin
          Notification.find_by! dossier_id: @dossier_id, already_read: false, type_notif: @type_notif
        rescue ActiveRecord::RecordNotFound
          Notification.new dossier_id: @dossier_id, type_notif: @type_notif, liste: []
        end
  end

  def text_for_notif
    case @type_notif
      when 'commentaire'
        "#{notification.liste.size + 1} nouveau(x) commentaire(s) déposé(s)."
      else
        'Notification par défaut'
    end
  end
end