class Commentaire < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :champ
  belongs_to :piece_justificative

  mount_uploader :file, CommentaireFileUploader
  validates :file, file_size: { maximum: 20.megabytes, message: "La taille du fichier doit être inférieure à 20 Mo" }
  validate :is_virus_free?
  validates :body, presence: { message: "Votre message ne peut être vide" }

  default_scope { order(created_at: :asc) }
  scope :updated_since?, -> (date) { where('commentaires.updated_at > ?', date) }

  after_create :notify

  def header
    "#{sender}, #{I18n.l(created_at, format: '%d %b %Y %H:%M')}"
  end

  def sender
    if email.present?
      email.split('@').first
    end
  end

  def file_url
    if Flipflop.remote_storage?
      RemoteDownloader.new(file.path).url
    else
      file.url
    end
  end

  private

  def notify
    dossier_user_email = dossier.user.email
    invited_users_emails = dossier.invites.pluck(:email).to_a

    # - If the email is the contact email, the commentaire is a copy
    #   of an automated notification email we sent to a user, so do nothing.
    # - If a user or an invited user posted a commentaire, do nothing,
    #   the notification system will properly
    # - Otherwise, a gestionnaire posted a commentaire, we need to notify the user
    if !email.in?([CONTACT_EMAIL, dossier_user_email, *invited_users_emails])
      notify_user
    end
  end

  def notify_user
    DossierMailer.notify_new_answer(dossier).deliver_later
  end

  def is_virus_free?
    if file.present? && file_changed? && !ClamavService.safe_file?(file.path)
      errors.add(:file, "Virus détecté dans le fichier joint, merci de changer de fichier")
    end
  end
end
