class Notification < ActiveRecord::Base
  belongs_to :dossier
  enum type_notif: {
           commentaire: 'commentaire',
           cerfa: 'cerfa',
           piece_justificative: 'piece_justificative',
           champs: 'champs',
           submitted: 'submitted'
       }
  scope :unread, -> { where(already_read: false) }
end
