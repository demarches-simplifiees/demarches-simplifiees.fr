class Commentaire < ApplicationRecord
  belongs_to :dossier, inverse_of: :commentaires, touch: true

  belongs_to :user
  belongs_to :gestionnaire

  mount_uploader :file, CommentaireFileUploader
  validate :messagerie_available?, on: :create

  has_one_attached :piece_jointe

  validates :body, presence: { message: "Votre message ne peut être vide" }

  default_scope { order(created_at: :asc) }
  scope :updated_since?, -> (date) { where('commentaires.updated_at > ?', date) }

  after_create :notify

  def email
    if user
      user.email
    elsif gestionnaire
      gestionnaire.email
    else
      read_attribute(:email)
    end
  end

  def header
    "#{redacted_email}, #{I18n.l(created_at, format: '%d %b %Y %H:%M')}"
  end

  def redacted_email
    if gestionnaire.present?
      gestionnaire.email.split('@').first
    else
      email
    end
  end

  def sent_by_system?
    [CONTACT_EMAIL, OLD_CONTACT_EMAIL].include?(email) &&
      user.nil? && gestionnaire.nil?
  end

  def sent_by?(someone)
    email == someone.email
  end

  def file_url
    if piece_jointe.attached?
      if piece_jointe.virus_scanner.safe?
        Rails.application.routes.url_helpers.url_for(piece_jointe)
      end
    elsif Flipflop.remote_storage?
      RemoteDownloader.new(file.path).url
    elsif file&.url
      # FIXME: this is horrible but used only in dev and will be removed after migration
      File.join(LOCAL_DOWNLOAD_URL, file.url)
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

  def messagerie_available?
    return if sent_by_system?
    if dossier.present? && !dossier.messagerie_available?
      errors.add(:dossier, "Il n’est pas possible d’envoyer un message sur un dossier archivé ou en brouillon")
    end
  end
end
