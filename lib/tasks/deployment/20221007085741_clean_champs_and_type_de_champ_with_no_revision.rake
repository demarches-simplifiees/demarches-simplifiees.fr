# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: clean_champs_and_type_de_champ_with_no_revision'
  task clean_champs_and_type_de_champ_with_no_revision: :environment do
    puts "Running deploy task 'clean_champs_and_type_de_champ_with_no_revision'"

    champs = Champ.where(type_de_champ: TypeDeChamp.where.missing(:revisions))
    TypeDeChamp.where(id: champs.map(&:type_de_champ_id)).destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
