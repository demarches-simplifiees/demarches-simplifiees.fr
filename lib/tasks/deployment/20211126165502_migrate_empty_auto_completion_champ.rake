# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_empty_auto_completion_champ'
  task migrate_empty_auto_completion_champ: :environment do
    puts "Running deploy task 'migrate_empty_auto_completion_champ'"

    puts "migrating drop_down_list with empty option list & other option enabled to text field"
    tdcs = TypeDeChamp.where(type_champ: TypeDeChamp.type_champs.fetch(:drop_down_list))
    progress = ProgressReport.new(tdcs.count)
    tdcs.find_each do |tdc|
      if tdc.drop_down_options.blank? && tdc.drop_down_other
        puts "  migrating empty drop_down_list #{tdc.libelle}"
        tdc.type_champ = TypeDeChamp.type_champs.fetch(:text)
        tdc.save
        Champ.where(type: Champs::AutoCompletionChamp.to_s, type_de_champ: tdc).update_all(type: Champs::TextChamp.to_s)
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
