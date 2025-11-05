# frozen_string_literal: true

class InstructeurMailerPreview < ActionMailer::Preview
  def last_week_overview
    InstructeurMailer.last_week_overview(Instructeur.first)
  end

  def send_dossier
    InstructeurMailer.send_dossier(instructeur, Dossier.new(id: 10, procedure: procedure), target_instructeur)
  end

  def send_login_token
    InstructeurMailer.send_login_token(instructeur, "token")
  end

  def user_to_instructeur
    InstructeurMailer.user_to_instructeur(instructeur.email)
  end

  def trusted_device_token_renewal
    InstructeurMailer.trusted_device_token_renewal(instructeur, "renewal_token", 1.week.from_now)
  end

  def send_notifications
    data = [
      {
        procedure_libelle: 'une superbe démarche',
        procedure_id: 213,
        nb_en_construction: 2,
        nb_en_instruction: 2,
        nb_accepted: 4,
        nb_notification: 2,
      },
      {
        procedure_libelle: 'une démarche incroyable',
        procedure_id: 213,
        nb_en_construction: 1,
        nb_en_instruction: 2,
        nb_accepted: 5,
        nb_notification: 1,
      },
    ]
    InstructeurMailer.send_notifications(instructeur, data)
  end

  private

  def instructeur
    Instructeur.new(
      id: 10,
      user: User.new(email: 'instructeur@administration.gouv.fr')
    )
  end

  def target_instructeur
    Instructeur.new(
      id: 12,
      user: User.new(email: 'collegue@administration.gouv.fr')
    )
  end

  def procedure
    Procedure.new(id: 15, libelle: 'libelle')
  end

  def dossier
    Dossier.new(id: 15, procedure: procedure)
  end
end
