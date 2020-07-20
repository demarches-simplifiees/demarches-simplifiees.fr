class Commentaire < ApplicationRecord
  self.ignored_columns = ['file', 'piece_justificative_id']

  belongs_to :dossier, inverse_of: :commentaires, touch: true

  belongs_to :user, optional: true
  belongs_to :instructeur, optional: true

  validate :messagerie_available?, on: :create

  has_one_attached :piece_jointe

  validates :body, presence: { message: "ne peut être vide" }
  validates :piece_jointe, size: { less_than: 20.megabytes }

  default_scope { order(created_at: :asc) }
  scope :updated_since?, -> (date) { where('commentaires.updated_at > ?', date) }

  after_create :notify

  def email
    if user
      user.email
    elsif instructeur
      instructeur.email
    else
      read_attribute(:email)
    end
  end

  def header
    "#{redacted_email}, #{I18n.l(created_at, format: '%d %b %Y %H:%M')}"
  end

  def redacted_email
    if instructeur.present?
      if Flipper.enabled?(:hide_instructeur_email, dossier.procedure)
        "Instructeur n° #{instructeur.id}"
      else
        instructeur.email.split('@').first
      end
    else
      email
    end
  end

  def sent_by_system?
    [CONTACT_EMAIL, OLD_CONTACT_EMAIL].include?(email) &&
      user.nil? && instructeur.nil?
  end

  def sent_by?(someone)
    email == someone.email
  end

  def file_url
    if piece_jointe.attached? && piece_jointe.virus_scanner.safe?
      Rails.application.routes.url_helpers.url_for(piece_jointe)
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
    # - Otherwise, a instructeur posted a commentaire, we need to notify the user
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
