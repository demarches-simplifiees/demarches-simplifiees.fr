class Notification < ActiveRecord::Base
  enum type_notif: {
    commentaire: 'commentaire',
    cerfa: 'cerfa',
    piece_justificative: 'piece_justificative',
    champs: 'champs',
    submitted: 'submitted',
    avis: 'avis'
  }

  belongs_to :dossier

  scope :unread, -> { where(already_read: false) }
end
