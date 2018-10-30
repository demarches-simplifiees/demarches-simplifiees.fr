require Rails.root.join("lib", "tasks", "task_helper")

namespace :support do
  desc <<~EOD
    Give procedure #PROCEDURE_ID a new owner.
    The new owner can be specified with NEW_OWNER_ID or NEW_OWNER_EMAIL.
  EOD
  task transfer_procedure_ownership: :environment do
    new_owner_id = ENV['NEW_OWNER_ID']
    new_owner_email = ENV['NEW_OWNER_EMAIL']

    new_owner = nil
    if new_owner_id.present?
      rake_puts("Looking for new owner by id\n")
      new_owner = Administrateur.find(new_owner_id)
    elsif new_owner_email.present?
      rake_puts("Looking for new owner by email\n")
      new_owner = Administrateur.find_by('LOWER(email) = LOWER(?)', new_owner_email)
    end

    if new_owner.blank?
      fail "Must specify a new owner"
    end

    procedure_id = ENV['PROCEDURE_ID']
    procedure = Procedure.find(procedure_id)

    rake_puts("Changing owner of procedure ##{procedure_id} from ##{procedure.administrateur_id} to ##{new_owner.id}")
    procedure.update(administrateur: new_owner)
  end

  desc <<~EOD
    Give all procedures owned by OLD_OWNER_ID or OLD_OWNER_EMAIL a new owner.
    The new owner can be specified with NEW_OWNER_ID or NEW_OWNER_EMAIL.
  EOD
  task transfer_all_procedures_ownership: :environment do
    old_owner_id = ENV['OLD_OWNER_ID']
    old_owner_email = ENV['OLD_OWNER_EMAIL']
    new_owner_id = ENV['NEW_OWNER_ID']
    new_owner_email = ENV['NEW_OWNER_EMAIL']

    old_owner = nil

    if old_owner_id.present?
      rake_puts("Looking for old owner by id\n")
      old_owner = Administrateur.find(old_owner_id)
    elsif old_owner_email.present?
      rake_puts("Looking for old owner by email\n")
      old_owner = Administrateur.find_by('LOWER(email) = LOWER(?)', old_owner_email)
    end

    if old_owner.blank?
      fail "Must specify an old owner"
    end

    procedures = old_owner.procedures

    new_owner = nil
    if new_owner_id.present?
      rake_puts("Looking for new owner by id\n")
      new_owner = Administrateur.find(new_owner_id)
    elsif new_owner_email.present?
      rake_puts("Looking for new owner by email\n")
      new_owner = Administrateur.find_by('LOWER(email) = LOWER(?)', new_owner_email)
    end

    if new_owner.blank?
      fail "Must specify a new owner"
    end

    procedures.update_all(administrateur_id: new_owner.id)
  end

  desc <<~EOD
    Delete the user account for a given USER_EMAIL.
    Only works if the user has no dossier where the instruction has started.
  EOD
  task delete_user_account: :environment do
    user_email = ENV['USER_EMAIL']
    if user_email.nil?
      fail "Must specify a USER_EMAIL"
    end
    user = User.find_by(email: user_email)
    if user.dossiers.state_instruction_commencee.any?
      fail "Cannot delete this user because instruction has started for some dossiers"
    end
    user.dossiers.each(&:delete_and_keep_track)
    user.destroy
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
