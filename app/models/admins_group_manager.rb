class AdminsGroupManager < ApplicationRecord
  has_and_belongs_to_many :admins_groups

  belongs_to :user

  delegate :email, to: :user

  default_scope { eager_load(:user) }

  def self.by_email(email)
    find_by(users: { email: email })
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
    !(root_admins_group = admins_groups.where(admins_group: nil).first) || root_admins_group.admins_group_managers.size > 1
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
