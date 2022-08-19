require Rails.root.join("lib", "tasks", "task_helper")

namespace :support do
  desc <<~EOD
    Delete the user account for a given USER_EMAIL on the behalf of ADMIN_EMAIL.
    Only works if the user has no dossier where the instruction has started.
  EOD
  task delete_user_account: :environment do
    user_email = ENV['USER_EMAIL']
    fail "Must specify a USER_EMAIL" if user_email.nil?

    administration_email = ENV['ADMIN_EMAIL']
    fail "Must specify the ADMIN_EMAIL of the operator performing the deletion (yourself)" if administration_email.nil?

    user = User.find_by!(email: user_email)
    administration = Administration.find_by!(email: administration_email)

    user.delete_and_keep_track_dossiers(administration)
    user.destroy
  end

  desc <<~EOD
    Destroy all AdministrateursProcedures for a given USER_EMAIL
    Only works if the AdministrateursProcedures is not the last of the Procedure.
  EOD
  task delete_adminstrateurs_procedures: :environment do
    user_email = ENV['USER_EMAIL']
    fail "Must specify a USER_EMAIL" if user_email.nil?

    administrateur = Administrateur.joins(:user).where(user: { email: user_email }).first
    AdministrateursProcedure.where(administrateur: administrateur).each do |administrateur_procedure|
      procedure = administrateur_procedure.procedure
      if procedure.administrateurs.count > 1
        begin
          procedure.administrateurs.delete(administrateur)
          puts "Deleted #{user_email} from #{procedure.libelle}"
        rescue ActiveRecord::RecordInvalid
          puts "Can't unlink #{user_email} from <#{procedure.libelle}> due to error"
        end
      else
        puts "Can't unlink #{user_email} from <#{procedure.libelle}> because last admin"
      end
    end
  end

  desc <<~EOD
    Change the SIRET for a given dossier (specified by DOSSIER_ID)
  EOD
  task update_dossier_siret: :environment do
    siret_number = ENV['SIRET']
    dossier_id = ENV['DOSSIER_ID']

    if siret_number.nil?
      fail "Must specify a SIRET"
    end

    siret_number = siret_number.dup # Unfreeze the string
    siret = Siret.new(siret: siret_number)
    if siret.invalid?
      fail siret.errors.full_messages.to_sentence
    end

    dossier = Dossier.find(dossier_id)

    EtablissementUpdateJob.perform_now(dossier, siret_number)
  end

  desc <<~EOD
    Change a user’s mail from OLD_EMAIL to NEW_EMAIL.
    Also works for administrateurs and instructeurs.
  EOD
  task change_user_email: :environment do
    old_email = ENV['OLD_EMAIL']
    new_email = ENV['NEW_EMAIL']

    if User.find_by(email: new_email).present?
      fail "There is an existing account for #{new_email}, not overwriting"
    end

    user = User.find_by(email: old_email)

    if user.nil?
      fail "Couldn’t find existing account for #{old_email}"
    end

    user.update(email: new_email)
  end
end
