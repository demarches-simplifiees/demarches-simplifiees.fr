# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_empty_options_from_drop_down_list'
  task remove_empty_options_from_drop_down_list: :environment do
    ids = TypeDeChamp
      .where(type_champ: ['drop_down_list', 'multiple_drop_down_list', 'linked_drop_down_list'])
      .where("options->'drop_down_options' @> '[\"\"]'::jsonb").ids

    progress = ProgressReport.new(ids.count)

    TypeDeChamp.where(id: ids).select(:id, :options, :type_champ).find_each do |drop_down_list|
      drop_down_list.drop_down_options.delete('')
      drop_down_list.save!(validate: false)

      progress.inc
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
