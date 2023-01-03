namespace :after_party do
  desc 'Deployment task: normalize_yes_no_values'
  task normalize_yes_no_values: :environment do
    puts "Running deploy task 'normalize_yes_no_values'"

    scope_blank = Champs::YesNoChamp.where(value: '')
    scope_invalid = Champs::YesNoChamp.where.not(value: [nil, 'true', 'false'])

    progress = ProgressReport.new(scope_blank.count + scope_invalid.count)
    update_all(scope_blank, nil, progress)
    update_all(scope_invalid, 'false', progress)
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  private

  def update_all(scope, value, progress)
    scope.in_batches(of: 10_000) do |yes_no|
      progress.inc(yes_no.count)
      yes_no.update_all(value: value)
    end
  end
end
