class GroupeGestionnaire < ApplicationRecord
  has_many :administrateurs
  has_and_belongs_to_many :gestionnaires

  has_ancestry

  def add_gestionnaire(gestionnaire)
    return if gestionnaire.nil?
    return if in?(gestionnaire.groupe_gestionnaires)

    gestionnaires << gestionnaire
  end

  def remove_gestionnaire(gestionnaire_id, current_user)
    if !self.is_root? || self.gestionnaires.one?
      alert = "Suppression impossible : il doit y avoir au moins un gestionnaire dans le groupe racine"
    else
      gestionnaire = Gestionnaire.find(gestionnaire_id)

      if !in?(gestionnaire.groupe_gestionnaires) || !gestionnaire.groupe_gestionnaires.destroy(self)
        alert = "Le gestionnaire « #{gestionnaire.email} » n’est pas dans le groupe gestionnaire."
      else
        if gestionnaire.groupe_gestionnaires.empty?
          gestionnaire.destroy
        end
        notice = "Le gestionnaire « #{gestionnaire.email} » a été retiré du groupe gestionnaire."
        GroupeGestionnaireMailer
          .notify_removed_gestionnaire(self, gestionnaire.email, current_user.email)
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
    gestionnaires_to_add.each { add_gestionnaire(_1) }

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

  def add_administrateur(administrateur)
    return if administrateur.nil?
    return if id == administrateur.groupe_gestionnaire_id

    administrateurs << administrateur
  end

  def remove_administrateur(administrateur_id, current_user)
    administrateur = Administrateur.find(administrateur_id)

    if id != administrateur.groupe_gestionnaire_id
      alert = "L'administrateur « #{administrateur.email} » n’est pas dans le groupe gestionnaire."
    else
      administrateur.destroy
      notice = "L'administrateur « #{administrateur.email} » a été retiré du groupe gestionnaire."
      GroupeGestionnaireMailer
        .notify_removed_administrateur(self, administrateur.email, current_user.email)
        .deliver_later
    end
    [administrateur, alert, notice]
  end

  def add_administrateurs(ids: [], emails: [], current_user: nil)
    emails = emails.to_json
    emails = JSON.parse(emails).map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }

    administrateurs_to_add, valid_emails, invalid_emails = Administrateur.find_all_by_identifier_with_emails(ids:, emails:)
    not_found_emails = valid_emails - administrateurs_to_add.map(&:email)

    # Send invitations to users without account
    if not_found_emails.present?
      administrateurs_to_add += not_found_emails.map do |email|
        user = User.create_or_promote_to_administrateur(email, SecureRandom.hex)
        user.invite_administrateur!(self)
        user.administrateur
      end
    end
    administrateurs_already_in_groupe_gestionnaire = []
    # We dont't want to assign a user to an groupe_gestionnaire if they are already assigned to it
    administrateurs_duplicate = administrateurs_to_add & administrateurs
    administrateurs_to_add -= administrateurs
    administrateurs_to_add.each do |administrateur|
      if !current_user.is_a?(SuperAdmin) && administrateur.groupe_gestionnaire_id && ((administrateur.groupe_gestionnaire.ancestor_ids + [administrateur.groupe_gestionnaire_id]) & current_user.groupe_gestionnaire_ids).empty?
        administrateurs_already_in_groupe_gestionnaire << administrateur
        next
      end
      add_administrateur(administrateur)
    end

    if administrateurs_already_in_groupe_gestionnaire.present?
      alert = I18n.t('activerecord.errors.administrateurs_already_in_groupe_gestionnaire',
        count: administrateurs_already_in_groupe_gestionnaire.size,
        emails: administrateurs_already_in_groupe_gestionnaire)
    end

    if invalid_emails.present?
      alert = I18n.t('activerecord.wrong_address',
        count: invalid_emails.size,
        emails: invalid_emails)
    end
    if administrateurs_duplicate.present?
      alert = I18n.t('activerecord.errors.duplicate_email',
        count: invalid_emails.size,
        emails: administrateurs_duplicate.map(&:email))
    end

    if administrateurs_to_add.present?
      notice = "Les administrateurs ont bien été affectés au groupe gestionnaire"

      GroupeGestionnaireMailer
        .notify_added_administrateurs(self, administrateurs_to_add, current_user.email)
        .deliver_later
    end

    [administrateurs_to_add, alert, notice]
  end

  def can_be_deleted?(current_user)
    (gestionnaires.empty? || (gestionnaires == [current_user])) && administrateurs.empty? && children.empty?
  end
end
