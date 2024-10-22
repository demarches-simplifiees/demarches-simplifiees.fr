namespace :after_party do
  desc 'Deployment task: Enable feature flag for referentiel_de_polynesie'
  task feature_flag_referentiel_de_polynesie: :environment do
    puts "Running deploy task 'feature_flag_referentiel_de_polynesie'"

    progress = ProgressReport.new(User.count)
    User.find_each do |user|
      if Flipper.enabled?(:referentiel_de_polynesie, user) && user.administrateur?
        user.administrateur.procedures.each do |procedure|
          if procedure.types_de_champ_for_tags.where(type_champ: 'referentiel_de_polynesie').any?
            Flipper.enable(:referentiel_de_polynesie, procedure)
          end
        end
        Flipper.disable(:referentiel_de_polynesie, user)
      end
      progress.inc
    end

    progress.finish

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
