class Notification < ActiveRecord::Base
  belongs_to :dossier

  after_save :broadcast_notification

  enum type_notif: {
           commentaire: 'commentaire'
       }

  def broadcast_notification
    ActionCable.server.broadcast 'notifications',
                                 message: "Nouveau commentaire posté sur le dossier #{self.dossier.id}"
  end
end
