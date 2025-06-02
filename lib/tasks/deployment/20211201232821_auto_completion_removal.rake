# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: auto_completion_removal'
  task auto_completion_removal: :environment do
    puts "Running deploy task 'auto_completion_removal'"

    puts "migrating old auto_completion type_de_champ to drop_down list with other value"
    tdcs = TypeDeChamp.where(type_champ: 'auto_completion')
    progress = ProgressReport.new(tdcs.count)
    tdcs.find_each do |tdc|
      puts "  migrating auto_completion #{tdc.libelle}"
      tdc.drop_down_other = true
      tdc.type_champ = TypeDeChamp.type_champs.fetch(:drop_down_list)
      tdc.save
      progress.inc
    end
    progress.finish

    puts "migrating old auto_completion champs to drop_down_list with other value"
    Champ.where(type: 'Champs::AutoCompletionChamp').update_all(type: Champs::DropDownListChamp.to_s)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
