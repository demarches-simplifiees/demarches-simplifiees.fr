require Rails.root.join("lib", "tasks", "task_helper")

namespace :support do
  desc <<~EOD
    Give procedure #PROCEDURE_ID a new owner.
    The owner can be specified with NEW_OWNER_ID or NEW_OWNER_MAIL.
  EOD
  task transfer_procedure_ownership: :environment do
    new_owner_id = ENV['NEW_OWNER_ID']
    new_owner_mail = ENV['NEW_OWNER_MAIL']

    new_owner = nil
    if new_owner_id.present?
      new_owner = Administrateur.find(new_owner_id)
    elsif new_owner_mail.present?
      new_owner = Administrateur.find_by(email: new_owner_mail)
    end

    if new_owner.blank?
      fail "Must specify a new owner"
    end

    procedure_id = ENV['PROCEDURE_ID']
    procedure = Procedure.find(procedure_id)

    rake_puts("Changing owner of procedure ##{procedure_id} from ##{procedure.administrateur_id} to ##{new_owner.id}")
    procedure.update(administrateur: new_owner)

    ProcedurePath.where(procedure_id: procedure_id).each do |pp|
      rake_puts("Changing owner of procedure_path #{pp.path} from ##{pp.administrateur_id} to ##{new_owner.id}")
      pp.update(administrateur: new_owner)
    end
  end

  desc <<~EOD
    Delete the user account for a given USER_MAIL.
    Only works if the user has no dossier where the instruction has started.
  EOD
  task delete_user_account: :environment do
    user_mail = ENV['USER_MAIL']
    if user_mail.nil?
      fail "Must specify a USER_MAIL"
    end
    user = User.find_by(email: user_mail)
    if user.dossiers.state_instruction_commencee.any?
      fail "Cannot delete this user because instruction has started for some dossiers"
    end
    user.dossiers.each(&:delete_and_keep_track)
    user.destroy
  end
end
