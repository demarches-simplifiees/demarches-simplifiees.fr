class InstructeursImportService
  def import(procedure, groupes_emails)
    admins = procedure.administrateurs

    errors = []

    groupes_emails.each do |groupe_emails|
      groupe = groupe_emails["groupe"].strip
      instructeur_email = groupe_emails["email"].strip.downcase

      if groupe.present? && Devise.email_regexp.match?(instructeur_email)
        gi = procedure.groupe_instructeurs.find_or_create_by!(label: groupe)

        instructeur = Instructeur.by_email(instructeur_email) || create_instructeur(admins, instructeur_email)

        if !gi.instructeurs.include?(instructeur)
          gi.instructeurs << instructeur

        end
      else
        errors << instructeur_email
      end
    end

    errors
  end

  private

  def create_instructeur(administrateurs, email)
    user = User.create_or_promote_to_instructeur(
      email,
      SecureRandom.hex,
      administrateurs: administrateurs
    )
    user.invite!
    user.instructeur
  end
end
