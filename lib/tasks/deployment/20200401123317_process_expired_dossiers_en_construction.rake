# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: process_expired_dossiers_en_construction'
  task process_expired_dossiers_en_construction: :environment do
    puts "Running deploy task 'process_expired_dossiers_en_construction'"

    dossiers_close_to_expiration = Dossier
      .en_construction_close_to_expiration
      .without_en_construction_expiration_notice_sent

    Expired::DossiersDeletionService.send_expiration_notices(dossiers_close_to_expiration, :en_construction_close_to_expiration_notice_sent_at)

    BATCH_SIZE = 1000

    ((dossiers_close_to_expiration.count / BATCH_SIZE).ceil + 1).times do |n|
      dossiers_close_to_expiration
        .offset(n * BATCH_SIZE)
        .limit(BATCH_SIZE)
        .update_all(en_construction_close_to_expiration_notice_sent_at: Time.zone.now + n.days)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20200401123317'
  end
end
