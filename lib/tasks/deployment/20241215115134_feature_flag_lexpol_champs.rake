namespace :after_party do
  desc 'Deployment task: feature_flag_lexpol_champs'
  task feature_flag_lexpol_champs: :environment do
    puts "Running deploy task 'feature_flag_lexpol_champs'"

    progress = ProgressReport.new(User.count)
    User.find_each do |user|
      if Flipper.enabled?(:lexpol, user) && user.administrateur?
        user.administrateur.procedures.each do |procedure|
          if procedure.types_de_champ_for_tags.where(type_champ: 'lexpol').any?
            Flipper.enable(:lexpol, procedure)
          end
        end
        Flipper.disable(:lexpol, user)
      end
      progress.inc
    end

    progress.finish

    # Update task as completed.
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
