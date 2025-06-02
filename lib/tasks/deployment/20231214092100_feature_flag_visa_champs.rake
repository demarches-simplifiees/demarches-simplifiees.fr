# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: xxx'
  task feature_flag_visa_champs: :environment do
    puts "Running deploy task 'feature_flag_visa_champs'"

    progress = ProgressReport.new(User.count)
    User.find_each do |user|
      if Flipper.enabled?(:visa, user) && user.administrateur?
        user.administrateur.procedures.each do |procedure|
          if procedure.types_de_champ_for_tags.where(type_champ: 'visa').any?
            Flipper.enable(:visa, procedure)
          end
        end
        Flipper.disable(:visa, user)
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
