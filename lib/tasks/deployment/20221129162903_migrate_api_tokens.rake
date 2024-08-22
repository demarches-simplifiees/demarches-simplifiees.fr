# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_api_tokens'
  task migrate_api_tokens: :environment do
    puts "Running deploy task 'migrate_api_tokens'"

    administrateurs = Administrateur
      .where.not(encrypted_token: nil)
      .where.missing(:api_tokens)

    progress = ProgressReport.new(administrateurs.count)

    administrateurs.find_each do |administrateur|
      administrateur.transaction do
        administrateur
          .api_tokens
          .create!(name: administrateur.updated_at.strftime('Jeton d’API généré le %d/%m/%Y'),
            encrypted_token: administrateur.encrypted_token,
            version: 1)
        administrateur.update_column(:encrypted_token, nil)
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
