class GroupeGestionnaire < ApplicationRecord
  has_many :administrateurs
  has_and_belongs_to_many :gestionnaires

  has_ancestry

  def add(gestionnaire)
    return if gestionnaire.nil?
    return if in?(gestionnaire.groupe_gestionnaires)

    gestionnaires << gestionnaire
  end

  def remove(gestionnaire_id, current_user)
    if !self.is_root? || self.gestionnaires.one?
      alert = "Suppression impossible : il doit y avoir au moins un gestionnaire dans le groupe racine"
    else
      gestionnaire = Gestionnaire.find(gestionnaire_id)

      if gestionnaire.nil? || !in?(gestionnaire.groupe_gestionnaires) || !gestionnaire.groupe_gestionnaires.destroy(self)
        alert = "Le gestionnaire « #{gestionnaire.email} » n’est pas dans le groupe."
      else
        if gestionnaire.groupe_gestionnaires.empty?
          gestionnaire.destroy
        end
        notice = "Le gestionnaire « #{gestionnaire.email} » a été retiré du groupe."
        GroupeGestionnaireMailer
          .notify_removed_gestionnaire(self, gestionnaire, current_user.email)
          .deliver_later
      end
    end
    [gestionnaire, alert, notice]
  end

  def add_gestionnaires(ids: [], emails: [], current_user: nil)
    emails = emails.to_json
    emails = JSON.parse(emails).map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }

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
    gestionnaires_duplicate = gestionnaires_to_add & gestionnaires
    gestionnaires_to_add -= gestionnaires
    gestionnaires_to_add.each { add(_1) }

    if invalid_emails.present?
      alert = I18n.t('activerecord.wrong_address',
        count: invalid_emails.size,
        emails: invalid_emails)
    end
    if gestionnaires_duplicate.present?
      alert = I18n.t('activerecord.errors.duplicate_email',
        count: invalid_emails.size,
        emails: gestionnaires_duplicate.map(&:email))
    end

    if gestionnaires_to_add.present?
      notice = "Les gestionnaires ont bien été affectés au groupe gestionnaire"

      GroupeGestionnaireMailer
        .notify_added_gestionnaires(self, gestionnaires_to_add, current_user.email)
        .deliver_later
    end

    [gestionnaires_to_add, alert, notice]
  end

  def can_be_deleted?(current_user)
    (gestionnaires.empty? || (gestionnaires == [current_user])) && administrateurs.empty? && children.empty?
  end
end
