class NotificationService
  def initialize type_notif, dossier_id, attribut_change=''
    @type_notif = type_notif
    @dossier_id = dossier_id

    notification.liste.push text_for_notif attribut_change
    notification.liste = notification.liste.uniq

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

  def text_for_notif attribut=''
    case @type_notif
    when 'commentaire'
      "#{notification.liste.size + 1} nouveau(x) commentaire(s) déposé(s)."
    when 'cerfa'
      "Un nouveau formulaire a été déposé."
    when 'piece_justificative'
      attribut
    when 'champs'
      attribut
    when 'submitted'
      "Le dossier nº #{@dossier_id} a été déposé."
    when 'avis'
      'Un nouvel avis a été rendu'
    else
      'Notification par défaut'
    end
  end
end
