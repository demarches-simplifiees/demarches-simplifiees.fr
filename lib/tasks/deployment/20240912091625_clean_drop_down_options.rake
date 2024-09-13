# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: clean_drop_down_options'
  task clean_drop_down_options: :environment do
    puts "Running deploy task 'clean_drop_down_options'"

    ids = TypeDeChamp
      .where(type_champ: ['drop_down_list', 'multiple_drop_down_list'])
      .where("EXISTS ( select 1 FROM jsonb_array_elements_text(options->'drop_down_options') AS element WHERE element ~ '^--.*--$')").ids

    progress = ProgressReport.new(ids.count)

    TypeDeChamp.where(id: ids).find_each do |type_de_champ|
      type_de_champ.drop_down_options = type_de_champ.drop_down_options.reject { |option| option.match?(/^--.*--$/) }
      type_de_champ.save!(validate: false)

      progress.inc
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
