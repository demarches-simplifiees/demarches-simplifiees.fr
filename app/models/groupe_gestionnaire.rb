class GroupeGestionnaire < ApplicationRecord
  belongs_to :groupe_gestionnaire, optional: true # parent
  has_many :children, class_name: "GroupeGestionnaire", inverse_of: :groupe_gestionnaire
  has_many :administrateurs
  has_and_belongs_to_many :gestionnaires

  def root_groupe_gestionnaire?
    groupe_gestionnaire.nil?
  end

  def add(gestionnaire)
    return if gestionnaire.nil?
    return if in?(gestionnaire.groupe_gestionnaires)

    gestionnaires << gestionnaire
  end

  def remove(gestionnaire)
    return if gestionnaire.nil?
    return if !in?(gestionnaire.groupe_gestionnaires)

    gestionnaire.groupe_gestionnaires.destroy(self)
  end

  def add_gestionnaires(ids: [], emails: [])
    gestionnaires_to_add, valid_emails, invalid_emails = Gestionnaire.find_all_by_identifier_with_emails(ids:, emails:)
    not_found_emails = valid_emails - gestionnaires_to_add.map(&:email)

    # Send invitations to users without account
    if not_found_emails.present?
      gestionnaires_to_add += not_found_emails.map do |email|
        user = User.create_or_promote_to_gestionnaire(email, SecureRandom.hex)
        user.invite_gestionnaire!(self)
        user.gestionnaire
      end
    end

    # We dont't want to assign a user to an groupe_gestionnaire if they are already assigned to it
    gestionnaires_to_add -= gestionnaires
    gestionnaires_to_add.each { add(_1) }

    [gestionnaires_to_add, invalid_emails]
  end
end
