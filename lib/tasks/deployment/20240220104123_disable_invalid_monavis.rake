# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: disable_invalid_monavis'
  task disable_invalid_monavis: :environment do
    puts "Running deploy task 'disable_invalid_monavis'"
    # rubocop:disable DS/Unscoped
    all_procedures = Procedure.unscoped.where.not(monavis_embed: nil)
    # rubocop:enable DS/Unscoped
    progress = ProgressReport.new(all_procedures.count)

    all_procedures.find_each do |procedure|
      if !procedure.valid? && procedure.errors.key?(:monavis_embed)
        procedure.update_column(:monavis_embed, '')
        rake_puts "fix: #{procedure.id}"
      end
      progress.inc(1)
    end
    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
