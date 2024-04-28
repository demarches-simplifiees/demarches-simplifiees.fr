# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: destroy_dossier_transfer_without_email'
  task destroy_dossier_transfer_without_email: :environment do
    puts "Running deploy task 'destroy_dossier_transfer_without_email'"

    invalid_dossiers = DossierTransfer.where(email: "")

    progress = ProgressReport.new(invalid_dossiers.count)

    invalid_dossiers.find_each do |dossier_transfer|
      puts "Destroy dossier transfer #{dossier_transfer.id}"
      dossier_transfer.destroy_and_nullify

      job = Delayed::Job.where("handler LIKE ALL(ARRAY[?, ?])", "%ActionMailer::MailDeliveryJob%", "%aj_globalid: gid://tps/DossierTransfer/#{dossier_transfer.id}\n%").first
      job.destroy if job

      progress.inc
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
