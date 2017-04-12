class Notification < ActiveRecord::Base
  belongs_to :dossier

  # after_save :broadcast_notification

  enum type_notif: {
           commentaire: 'commentaire',
           cerfa: 'cerfa',
           piece_justificative: 'piece_justificative',
           champs: 'champs',
           submitted: 'submitted'
       }

  # def broadcast_notification
  #   ActionCable.server.broadcast 'notifications',
  #                                message: "Dossier n°#{self.dossier.id} : #{self.liste.last}",
  #                                dossier: {id: self.dossier.id}
  # end
end
