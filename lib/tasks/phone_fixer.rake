require Rails.root.join("lib", "tasks", "task_helper")

namespace :phone_fixer do
  desc <<~EOD
    Given a procedure_id in argument, run the PhoneFixer.
    ex: rails phone_fixer:run\[1\]
  EOD
  task :run, [:procedure_id] => :environment do |_t, args|
    procedure = Procedure.find(args[:procedure_id])

    phone_champs = Champ
      .where(dossier_id: procedure.dossiers.pluck(:id))
      .where(type: "Champs::PhoneChamp")

    invalid_phone_champs = phone_champs.reject(&:valid?)

    fixable_phone_champs = invalid_phone_champs.filter { |phone| PhoneFixer.fixable?(phone.value) }

    fixable_phone_champs.each do |phone|
      fixable_phone_value = phone.value
      fixed_phone_value = PhoneFixer.fix(fixable_phone_value)
      if phone.update(value: fixed_phone_value)
        rake_puts "Invalid phone #{fixable_phone_value} is fixed as #{fixed_phone_value}"
      else
        rake_puts "Failed to fix #{fixable_phone_value}"
      end
    end
  end
end
