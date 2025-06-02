# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :procedures do
  desc <<~EOD
    falsify opendata flag for some procedures
    rails procedures:falsify_opendata_procedures\[csv_path\]
  EOD
  task :falsify_opendata_procedures, [:csv] => :environment do |_t, args|
    csv = args[:csv]
    lines = CSV.readlines(csv, headers: true)

    rake_puts "Passage du flag opendata à false pour certaines procédures en cours..."

    errors =
      FalsifyOpendataService.call(lines)

    if errors.present?
      errors.each { |error| rake_puts error }
    end

    rake_puts "Mise à jour terminée"
  end
end
