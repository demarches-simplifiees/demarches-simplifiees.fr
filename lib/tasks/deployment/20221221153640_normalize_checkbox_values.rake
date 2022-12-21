namespace :after_party do
  desc 'Deployment task: normalize_checkbox_values'
  task normalize_checkbox_values: :environment do
    puts "Running deploy task 'normalize_checkbox_values'"

    Champs::CheckboxChamp.where(value: '').in_batches { |checkboxes| checkboxes.update_all(value: nil) }
    Champs::CheckboxChamp.where(value: 'on').in_batches { |checkboxes| checkboxes.update_all(value: 'true') }
    Champs::CheckboxChamp.where(value: 'off').in_batches { |checkboxes| checkboxes.update_all(value: 'false') }
    Champs::CheckboxChamp.where.not(value: [nil, 'true', 'false']).in_batches { |checkboxes| checkboxes.update_all(value: 'false') }

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
