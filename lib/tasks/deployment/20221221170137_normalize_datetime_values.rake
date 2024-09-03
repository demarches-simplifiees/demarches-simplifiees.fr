# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: normalize_datetime_values'
  task normalize_datetime_values: :environment do
    puts "Running deploy task 'normalize_datetime_values'"

    # Put your task implementation HERE.
    Champs::DatetimeChamp.in_batches do |datetime_champs|
      Migrations::BatchUpdateDatetimeValuesJob.perform_later(datetime_champs.pluck(:id))
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
