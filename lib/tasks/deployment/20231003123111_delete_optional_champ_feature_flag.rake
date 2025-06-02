# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: delete_optional_champ_feature_flag'
  task delete_optional_champ_feature_flag: :environment do
    puts "Running deploy task 'delete_optional_champ_feature_flag'"

    Flipper::Adapters::ActiveRecord::Gate.where(feature_key: 'disable_label_optional_champ_2023_06_29').destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
