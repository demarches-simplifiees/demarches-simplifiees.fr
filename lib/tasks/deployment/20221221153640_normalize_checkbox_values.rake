namespace :after_party do
  desc 'Deployment task: normalize_checkbox_values'
  task normalize_checkbox_values: :environment do
    puts "Running deploy task 'normalize_checkbox_values'"

    scope_blank = Champs::CheckboxChamp.where(value: '')
    scope_on = Champs::CheckboxChamp.where(value: 'on')
    scope_off = Champs::CheckboxChamp.where(value: 'off')
    scope_invalid = Champs::CheckboxChamp.where.not(value: [nil, 'true', 'false'])

    progress = ProgressReport.new(scope_blank.count + scope_on.count + scope_off.count + scope_invalid.count)
    update_all(scope_blank, nil, progress)
    update_all(scope_on, 'true', progress)
    update_all(scope_off, 'false', progress)
    update_all(scope_invalid, 'false', progress)
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  private

  def update_all(scope, value, progress)
    scope.in_batches(of: 10_000) do |checkboxes|
      progress.inc(checkboxes.count)
      checkboxes.update_all(value: value)
    end
  end
end
