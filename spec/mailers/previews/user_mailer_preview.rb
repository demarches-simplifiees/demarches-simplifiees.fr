class UserMailerPreview < ActionMailer::Preview
  def new_account_warning
    UserMailer.new_account_warning(user)
  end

  def new_account_warning___with_procedure
    procedure = Procedure.new(libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019', path: 'dotation-etr')
    UserMailer.new_account_warning(user, procedure)
  end

  def ask_for_merge
    UserMailer.ask_for_merge(user, 'dircab@territoires.gouv.fr')
  end

  def france_connect_merge_confirmation
    UserMailer.france_connect_merge_confirmation('new.exemple.fr', '123456', 15.minutes.from_now)
  end

  def send_archive
    UserMailer.send_archive(Instructeur.first, Procedure.first, Archive.first)
  end

  private

  def user
    User.new(id: 10, email: 'test@exemple.fr')
  end
end
