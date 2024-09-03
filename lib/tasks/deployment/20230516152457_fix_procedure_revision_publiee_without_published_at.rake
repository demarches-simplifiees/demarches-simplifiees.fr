# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_procedure_revision_publiee_without_published_at'
  task fix_procedure_revision_publiee_without_published_at: :environment do
    puts "Running deploy task 'fix_procedure_revision_publiee_without_published_at'"

    Procedure.unscoped.publiees_ou_closes.includes(:published_revision).find_each do |procedure| # rubocop:disable DS/Unscoped
      next unless procedure.published_revision.published_at.nil?

      rake_puts "Found Procedure##{procedure.id}, set published_at on published revision ##{procedure.published_revision.id}: #{procedure.published_at}"
      procedure.published_revision.update!(published_at: procedure.published_at)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
