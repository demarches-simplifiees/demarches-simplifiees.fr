class InstructeursImportService
  def self.import_groupes(procedure, groupes_emails)
    created_at = Time.zone.now
    updated_at = Time.zone.now

    groupes_emails, error_groupe_emails = groupes_emails
      .map { |groupe_email| { "groupe" => groupe_email["groupe"].present? ? groupe_email["groupe"].strip : nil, "email" => groupe_email["email"].present? ? groupe_email["email"].gsub(/[[:space:]]/, '').downcase : nil } }
      .partition { |groupe_email| groupe_email['groupe'].present? }

    errors = error_groupe_emails.map { |group_email| group_email['email'] }

    target_labels = groupes_emails.map { |groupe_email| groupe_email['groupe'] }.uniq
    missing_labels = target_labels - procedure.groupe_instructeurs.pluck(:label)

    if missing_labels.present?
      GroupeInstructeur.insert_all(missing_labels.map { |label| { label: label, procedure_id: procedure.id, created_at: created_at, updated_at: updated_at } })
    end

    target_groupes = procedure.reload.groupe_instructeurs

    defaut_groupe_instructeur = procedure.defaut_groupe_instructeur

    instructeurs_emails = groupes_emails.map { |instructeur_email| instructeur_email["email"] }.uniq

    instructeurs, invalid_emails = defaut_groupe_instructeur.add_instructeurs(emails: instructeurs_emails)

    if instructeurs.present?
      groupes_emails.each do |groupe_email|
        gi = target_groupes.find { |g| g.label == groupe_email['groupe'] }
        instructeur = Instructeur.where(users: { email: groupe_email['email'] }).first

        gi.add(instructeur)
      end
    end
    errors << invalid_emails
    errors.flatten
  end

  def self.import_instructeurs(procedure, emails)
    instructeurs_emails = emails.map { |instructeur_email| instructeur_email["email"].present? ? instructeur_email["email"].gsub(/[[:space:]]/, '').downcase : nil }

    groupe_instructeur = procedure.defaut_groupe_instructeur

    instructeurs, invalid_emails = groupe_instructeur.add_instructeurs(emails: instructeurs_emails)

    instructeurs.each { groupe_instructeur.add(_1) } if instructeurs.present?

    invalid_emails
  end
end
