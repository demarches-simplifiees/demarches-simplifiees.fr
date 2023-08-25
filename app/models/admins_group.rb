class AdminsGroup < ApplicationRecord
  belongs_to :admins_group, optional: true # parent
  has_many :children, class_name: "AdminsGroup", inverse_of: :admins_group
  has_many :administrateurs
  has_and_belongs_to_many :admins_group_managers

  def add(admins_group_manager)
    admins_group_managers << admins_group_manager
  end

  def add_admins_group_managers(ids: [], emails: [])
    admins_group_managers_to_add, valid_emails, invalid_emails = AdminsGroupManager.find_all_by_identifier_with_emails(ids:, emails:)
    not_found_emails = valid_emails - admins_group_managers_to_add.map(&:email)

    # Send invitations to users without account
    if not_found_emails.present?
      admins_group_managers_to_add += not_found_emails.map do |email|
        user = User.create_or_promote_to_admins_group_manager(email, SecureRandom.hex)
        user.invite_admins_group_manager!(self)
        user.admins_group_manager
      end
    end

    # We dont't want to assign a user to an admins_group if they are already assigned to it
    admins_group_managers_to_add -= admins_group_managers
    admins_group_managers_to_add.each { add(_1) }

    [admins_group_managers_to_add, invalid_emails]
  end
end
