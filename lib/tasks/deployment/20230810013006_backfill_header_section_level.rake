# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill new header_section_level in HeaderChamp with pf level attribute'
  task backfill_header_section_level: :environment do
    puts "Running deploy task 'backfill_header_section_level'"

    # rubocop:disable DS/Unscoped
    header_sections = TypeDeChamp
      .unscoped
      .includes(:piece_justificative_template_attachment)
      .where(type_champ: TypeDeChamp.type_champs.fetch(:header_section))
    progress = ProgressReport.new(header_sections.count)

    header_sections.find_each do |type_de_champ|
      type_de_champ.header_section_level = type_de_champ.level.presence || "1"
      type_de_champ.save
      progress.inc
    end
    # rubocop:enable DS/Unscoped

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
