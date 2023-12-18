namespace :after_party do
  desc 'Deployment task: xxx'
  task feature_flag_visa_champs: :environment do
    puts "Running deploy task 'feature_flag_visa_champs'"

    progress = ProgressReport.new(User.all.count)
    User.all.each do |user|
      if Flipper.enabled?(:visa, user) && user.administrateur?
        user.administrateur.procedures.each do |procedure|
          procedure.types_de_champ_for_tags.each do |types_de_champ_for_tags|
            if types_de_champ_for_tags.type_champ == 'visa'
              Flipper.enable(:visa, procedure)
              break
            end
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
