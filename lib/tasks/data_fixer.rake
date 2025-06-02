# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :data_fixer do
  desc <<~EOD
    Given a procedure_id in argument, run the DataFixer::ChampsPhoneInvalid.
    ex: rails data_fixer:fix_phones\[1\]
  EOD
  task :fix_phones, [:procedure_id] => :environment do |_t, args|
    procedure = Procedure.find(args[:procedure_id])

    phone_champs = Champ
      .where(dossier_id: procedure.dossiers.pluck(:id))
      .where(type: "Champs::PhoneChamp")

    invalid_phone_champs = phone_champs.reject(&:valid?)

    fixable_phone_champs = invalid_phone_champs.filter { |phone| DataFixer::ChampsPhoneInvalid.fixable?(phone.value) }

    fixable_phone_champs.each do |phone|
      fixable_phone_value = phone.value
      fixed_phone_value = DataFixer::ChampsPhoneInvalid.fix(fixable_phone_value)
      if phone.update(value: fixed_phone_value)
        rake_puts "Invalid phone #{fixable_phone_value} is fixed as #{fixed_phone_value}"
      else
        rake_puts "Failed to fix #{fixable_phone_value}"
      end
    end
  end

  desc <<~EOD
    Given a dossier_id in argument, run the DossierChampsMissing.
    ex: rails data_fixer:dossier_missing_champ\[1\]
  EOD
  task :dossier_missing_champ, [:dossier_id] => :environment do |_t, args|
    dossier = Dossier.find(args[:dossier_id])
    result = DataFixer::DossierChampsMissing.new(dossier:).fix

    if result > 0
      rake_puts "Dossier#[#{args[:dossier_id]}] fixed"
    else
      rake_puts "Dossier#[#{args[:dossier_id]}] not fixed"
    end
  end
end
