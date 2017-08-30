class Notification < ActiveRecord::Base
  enum type_notif: {
    commentaire: 'commentaire',
    cerfa: 'cerfa',
    piece_justificative: 'piece_justificative',
    champs: 'champs',
    submitted: 'submitted',
    avis: 'avis'
  }

  DEMANDE = %w(cerfa piece_justificative champs submitted)
  INSTRUCTION = %w(avis)
  MESSAGERIE = %w(commentaire)

  belongs_to :dossier

  scope :unread,       -> { where(already_read: false) }
  scope :demande,      -> { where(type_notif: DEMANDE) }
  scope :instruction,  -> { where(type_notif: INSTRUCTION) }
  scope :messagerie,   -> { where(type_notif: MESSAGERIE) }
  scope :mark_as_read, -> { update_all(already_read: true) }

  def demande?
    Notification::DEMANDE.include?(type_notif)
  end

  def instruction?
    Notification::INSTRUCTION.include?(type_notif)
  end

  def messagerie?
    Notification::MESSAGERIE.include?(type_notif)
  end
end
