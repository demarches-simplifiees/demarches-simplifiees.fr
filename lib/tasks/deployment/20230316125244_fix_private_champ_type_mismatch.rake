# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_private_champ_type_mismatch'
  task fix_private_champ_type_mismatch: :environment do
    puts "Running deploy task 'fix_private_champ_type_mismatch'"

    champs = Champ.private_only

    # count of large champs count is too slow, so we're using an progress approximation based on id
    progress = ProgressReport.new(champs.last.id)

    champs.includes(:type_de_champ).in_batches.each_record do |champ|
      type_champ = champ.type_de_champ.type_champ
      expected_type = "Champs::#{type_champ.classify}Champ"

      if champ.type != expected_type
        puts "Fixing champ #{champ.id} (#{champ.type} -> #{expected_type})"
        champ.update_column(:type, expected_type)
      end

      progress.set(champ.id)
    end

    progress.finish

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
