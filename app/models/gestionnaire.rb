class Gestionnaire < ApplicationRecord
  has_and_belongs_to_many :groupe_gestionnaires

  belongs_to :user

  delegate :email, to: :user

  default_scope { eager_load(:user) }

  def self.by_email(email)
    find_by(users: { email: email })
  end

  def email
    user&.email
  end

  def active?
    user&.active?
  end

  def self.find_all_by_identifier(ids: [], emails: [])
    find_all_by_identifier_with_emails(ids:, emails:).first
  end

  def self.find_all_by_identifier_with_emails(ids: [], emails: [])
    valid_emails, invalid_emails = emails.partition { URI::MailTo::EMAIL_REGEXP.match?(_1) }

    [
      where(id: ids).or(where(users: { email: valid_emails })).distinct(:id),
      valid_emails,
      invalid_emails
    ]
  end

  def can_be_deleted?
    !(root_groupe_gestionnaire = groupe_gestionnaires.where(groupe_gestionnaire: nil).first) || root_groupe_gestionnaire.gestionnaires.size > 1
  end

  def registration_state
    if user.active?
      'Actif'
    elsif user.reset_password_period_valid?
      'En attente'
    else
      'Expiré'
    end
  end
end
