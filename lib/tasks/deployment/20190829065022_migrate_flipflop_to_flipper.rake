namespace :after_party do
  desc 'Deployment task: migrate_flipflop_to_flipper'
  task migrate_flipflop_to_flipper: :environment do
    puts "Running deploy task 'migrate_flipflop_to_flipper'"

    Instructeur.includes(:user).find_each do |instructeur|
      if instructeur.features['download_as_zip_enabled']
        pp "enable :instructeur_download_as_zip for #{instructeur.user.email}"
        Flipper.enable_actor(:instructeur_download_as_zip, instructeur.user)
      end
      if instructeur.features['bypass_email_login_token']
        pp "enable :instructeur_bypass_email_login_token for #{instructeur.user.email}"
        Flipper.enable_actor(:instructeur_bypass_email_login_token, instructeur.user)
      end
    end

    Administrateur.includes(:user).find_each do |administrateur|
      if administrateur.features['web_hook']
        pp "enable :administrateur_web_hook for #{administrateur.user.email}"
        Flipper.enable_actor(:administrateur_web_hook, administrateur.user)
      end

      if administrateur.features['champ_integer_number']
        pp "enable :administrateur_champ_integer_number for #{administrateur.user.email}"
        Flipper.enable_actor(:administrateur_champ_integer_number, administrateur.user)
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190829065022'
  end
end
