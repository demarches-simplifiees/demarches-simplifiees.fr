# frozen_string_literal: true

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

    user.delete_and_keep_track_dossiers_also_delete_user(administration, reason: :user_removed)
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
    AdministrateursProcedure.where(administrateur: administrateur).find_each do |administrateur_procedure|
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

  task remove_ex_team_member: :environment do
    super_admin = SuperAdmin.find_by(email: ENV['SUPER_ADMIN_EMAIL'])
    fail "Must specify the ADMIN_EMAIL of the operator performing the deletion (yourself)" if super_admin.nil?
    super_admin_admin = User.find_by(email: super_admin.email).administrateur

    user = User.find_by!(email: ENV['USER_EMAIL'])
    fail "Must specify a USER_EMAIL" if user.nil?

    ActiveRecord::Base.transaction do
      # destroy all en_instruction dossier
      # because the normal workflow forbid to hide them.
      rake_puts "brutally deleting #{user.dossiers.en_instruction.count} en_instruction dossiers"
      user.dossiers.en_instruction.destroy_all

      # remove all the other dossier from the user side
      rake_puts "hide #{user.reload.dossiers.count} dossiers"
      user.delete_and_keep_track_dossiers(super_admin, reason: :user_removed)

      owned_procedures, shared_procedures = user.administrateur
        .procedures
        .partition { _1.administrateurs.one? }

      rake_puts "unlink #{shared_procedures.count} shared procedures"
      shared_procedures.each { _1.administrateurs.delete(user.administrateur) }

      procedures_without_dossier, procedures_with_dossiers =
        owned_procedures.partition { _1.dossiers.empty? }

      rake_puts "discard #{procedures_without_dossier.count} procedures without dossier"
      procedures_without_dossier.each { _1.discard_and_keep_track!(super_admin) }

      procedures_with_only_admin_dossiers,
        other_procedures = procedures_with_dossiers.partition do |p|
          p.dossiers.all? { _1.user == user || _1.deleted_user_email_never_send == user.email }
        end

      rake_puts "discard #{procedures_with_only_admin_dossiers.count} procedures with only admin dossiers"
      # TODO: clean this ugly hack to delete dossier from admin side
      procedures_with_only_admin_dossiers.each { _1.discard_and_keep_track!(super_admin_admin) }

      rake_puts "#{other_procedures.count} remaining"
    end
  end
end
