class Commentaire < ActiveRecord::Base
  belongs_to :dossier, touch: true
  belongs_to :champ
  belongs_to :piece_justificative

  mount_uploader :file, CommentaireFileUploader
  validates :file, file_size: { maximum: 20.megabytes, message: "La taille du fichier doit être inférieure à 20 Mo" }
  validate :is_virus_free?

  default_scope { order(created_at: :asc) }
  scope :updated_since?, -> (date) { where('commentaires.updated_at > ?', date) }

  after_create :notify

  def header
    "#{email}, " + I18n.l(created_at.localtime, format: '%d %b %Y %H:%M')
  end

  private

  def notify
    dossier_user_email = dossier.user.email
    invited_users_emails = dossier.invites_user.pluck(:email).to_a

    case email
    when I18n.t("dynamics.contact_email")
      # The commentaire is a copy of an automated notification email
      # we sent to a user, so do nothing
    when dossier_user_email, *invited_users_emails
      # A user or an inved user posted a commentaire,
      # we need to notify the gestionnaires

      notify_gestionnaires
    else
      # A gestionnaire posted a commentaire,
      # we need to notify the user

      notify_user
    end
  end

  def notify_gestionnaires
    NotificationService.new('commentaire', self.dossier.id).notify
  end

  def notify_user
    NotificationMailer.new_answer(dossier).deliver_now!
  end

  def is_virus_free?
    if file.present? && file_changed? && !ClamavService.safe_file?(file.path)
      errors.add(:file, "Virus détecté dans le fichier joint, merci de changer de fichier")
    end
  end
end
