# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: drop_down_other_migration'
  task drop_down_other_migration: :environment do
    puts "Running deploy task 'drop_down_other_migration'"

    puts "migrating old DropDownList with autre value"
    tdcs = TypeDeChamp.where(type_champ: TypeDeChamp.type_champs.fetch(:drop_down_list))
    progress = ProgressReport.new(tdcs.count)
    tdcs.find_each do |tdc|
      if tdc.drop_down_options&.any? { |option| option.casecmp('autre') == 0 }
        puts " migrating #{tdc.libelle}"
        tdc.drop_down_other = true
        tdc.drop_down_options = tdc.drop_down_options.reject { |o| o.casecmp('autre') == 0 }
        tdc.save
      end
      progress.inc
    end
    progress.finish

    puts "migrating old auto_completion to drop_down list with other value"
    tdcs = TypeDeChamp.where(type_champ: TypeDeChamp.type_champs.fetch(:auto_completion))
    progress = ProgressReport.new(tdcs.count)
    tdcs.find_each do |tdc|
      puts "  migrating auto_completion #{tdc.libelle}"
      tdc.drop_down_other = true
      tdc.type_champ = TypeDeChamp.type_champs.fetch(:drop_down_list)
      tdc.save
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
