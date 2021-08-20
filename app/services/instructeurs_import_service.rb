class InstructeursImportService
  def self.import(procedure, groupes_emails)
    created_at = Time.zone.now
    updated_at = Time.zone.now

    admins = procedure.administrateurs

    groupes_emails, error_groupe_emails = groupes_emails
      .map { |groupe_email| { "groupe" => groupe_email["groupe"].present? ? groupe_email["groupe"].strip : nil, "email" => groupe_email["email"].present? ? groupe_email["email"].gsub(/[[:space:]]/, '').downcase : nil } }
      .partition { |groupe_email| Devise.email_regexp.match?(groupe_email['email']) && groupe_email['groupe'].present? }

    errors = error_groupe_emails.map { |group_email| group_email['email'] }

    target_labels = groupes_emails.map { |groupe_email| groupe_email['groupe'] }.uniq
    missing_labels = target_labels - procedure.groupe_instructeurs.pluck(:label)

    if missing_labels.present?
      GroupeInstructeur.insert_all(missing_labels.map { |label| { label: label, procedure_id: procedure.id, created_at: created_at, updated_at: updated_at } })
    end

    target_groupes = procedure.reload.groupe_instructeurs

    target_emails = groupes_emails.map { |groupe_email| groupe_email["email"] }.uniq

    existing_emails = Instructeur.where(user: { email: target_emails }).pluck(:email)
    missing_emails = target_emails - existing_emails
    missing_emails.each { |email| create_instructeur(admins, email) }

    target_instructeurs = User.where(email: target_emails).map(&:instructeur)

    groupes_emails.each do |groupe_email|
      gi = target_groupes.find { |g| g.label == groupe_email['groupe'] }
      instructeur = target_instructeurs.find { |i| i.email == groupe_email['email'] }

      if !gi.instructeurs.include?(instructeur)
        gi.instructeurs << instructeur
      end
    end

    errors
  end

  private

  def self.create_instructeur(administrateurs, email)
    user = User.create_or_promote_to_instructeur(
      email,
      SecureRandom.hex,
      administrateurs: administrateurs
    )
    user.invite!
    user.instructeur
  end
end
