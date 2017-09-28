class Notification < ActiveRecord::Base
  enum type_notif: {
    commentaire: 'commentaire',
    cerfa: 'cerfa',
    piece_justificative: 'piece_justificative',
    champs: 'champs',
    submitted: 'submitted',
    avis: 'avis',
    annotations_privees: 'annotations_privees'
  }

  DEMANDE = %w(cerfa piece_justificative champs submitted)
  AVIS = %w(avis)
  MESSAGERIE = %w(commentaire)
  ANNOTATIONS_PRIVEES = %w(annotations_privees)

  belongs_to :dossier

  scope :unread,              -> { where(already_read: false) }
  scope :demande,             -> { where(type_notif: DEMANDE) }
  scope :avis,                -> { where(type_notif: AVIS) }
  scope :messagerie,          -> { where(type_notif: MESSAGERIE) }
  scope :annotations_privees, -> { where(type_notif: ANNOTATIONS_PRIVEES) }
  scope :mark_as_read,        -> { update_all(already_read: true) }

  def demande?
    Notification::DEMANDE.include?(type_notif)
  end

  def avis?
    Notification::AVIS.include?(type_notif)
  end

  def messagerie?
    Notification::MESSAGERIE.include?(type_notif)
  end

  def annotations_privees?
    Notification::ANNOTATIONS_PRIVEES.include?(type_notif)
  end
end
