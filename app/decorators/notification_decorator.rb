class NotificationDecorator < Draper::Decorator
  delegate_all

  def index_display
    ['champs', 'piece_justificative'].include?(type_notif) ? type = liste.join(" ") : type = liste.last
    { dossier: "Dossier n°#{dossier.id}", date: updated_at.strftime('%d/%m %H:%M'), type: type }
  end
end
