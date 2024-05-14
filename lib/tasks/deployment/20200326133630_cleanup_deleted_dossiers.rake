# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: cleanup_deleted_dossiers'
  task cleanup_deleted_dossiers: :environment do
    puts "Running deploy task 'cleanup_deleted_dossiers'"

    DeletedDossier.where(state: :brouillon).destroy_all

    AfterParty::TaskRecord.create version: '20200326133630'
  end
end
