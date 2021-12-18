require Rails.root.join("lib", "tasks", "task_helper")

namespace :zones do
  desc <<~EOD
    Update zone to all procedures
    rails zones:update_zone_to_procedures\[csv_path\]
  EOD
  task :update_zone_to_procedures, [:csv] => :environment do |_t, args|
    csv = args[:csv]
    lines = CSV.readlines(csv, headers: true)

    rake_puts "Mise à jour des procédures en cours..."

    errors =
      UpdateZoneToProceduresService.call(lines)

    if errors.present?
      errors.each { |error| rake_puts error }
    end

    rake_puts "Mise à jour terminée"
  end
end
