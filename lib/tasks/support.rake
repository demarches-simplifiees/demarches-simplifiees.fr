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

    user.delete_and_keep_track_dossiers_also_delete_user(administration)
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
end
