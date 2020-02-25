class DeviseUserMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    DeviseUserMailer.confirmation_instructions(user, "faketoken", {})
  end

  def confirmation_instructions___with_procedure
    CurrentConfirmation.procedure_after_confirmation = procedure
    DeviseUserMailer.confirmation_instructions(user, "faketoken", {})
  end

  def reset_password_instructions
    DeviseUserMailer.reset_password_instructions(user, "faketoken", {})
  end

  private

  def user
    User.new(id: 10, email: "usager@example.com")
  end

  def procedure
    Procedure.new(id: 20, libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019', path: 'dotation-etr')
  end
end
