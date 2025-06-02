# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: strip_type_de_champ_libelle'
  task strip_type_de_champ_libelle: :environment do
    puts "Running deploy task 'strip_type_de_champ_libelle'"

    # ~ 152K records matched
    tdcs = TypeDeChamp.where("libelle LIKE ?", ' %').or(TypeDeChamp.where("libelle LIKE ?", '% '))
    progress = ProgressReport.new(tdcs.count)

    tdcs.find_each do |tdc|
      tdc.save!
      progress.inc
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
