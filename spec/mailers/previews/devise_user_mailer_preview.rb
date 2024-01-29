class DeviseUserMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    DeviseUserMailer.confirmation_instructions(user, "faketoken", {})
  end

  def confirmation_instructions___with_procedure
    CurrentConfirmation.procedure_after_confirmation = procedure
    DeviseUserMailer.confirmation_instructions(user, "faketoken", {})
  end

  def confirmation_instructions___with_procedure_and_prefill_token
    DeviseUserMailer.confirmation_instructions(user, "faketoken", procedure_after_confirmation: procedure, prefill_token: "prefill_token")
  end

  def reset_password_instructions
    DeviseUserMailer.reset_password_instructions(user, "faketoken", {})
  end

  def unlock_instructions
    DeviseUserMailer.unlock_instructions(user, "faketoken", {})
  end

  def email_changed
    DeviseUserMailer.email_changed(user, {})
  end

  def password_change
    DeviseUserMailer.password_change(user, {})
  end

  private

  def user
    User.new(id: 10, email: "usager@example.com", locale: ['en', 'fr'].sample)
  end

  def procedure
    Procedure.new(id: 20, libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019', path: 'dotation-etr')
  end
end
