# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_champs_engagement_to_checkbox'
  task migrate_champs_engagement_to_checkbox: :environment do
    puts "Running deploy task 'migrate_champs_engagement_to_checkbox'"

    TypeDeChamp.where(type_champ: 'engagement').in_batches do |relation_type_de_champs|
      relation_type_de_champs.update_all(type_champ: 'checkbox')
      Champ.where(type_de_champ: relation_type_de_champs).in_batches do |relation_champs|
        relation_champs.update_all(type: 'Champs::CheckboxChamp')
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
