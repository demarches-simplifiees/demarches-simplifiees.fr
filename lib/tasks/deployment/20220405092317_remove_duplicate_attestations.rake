# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_duplicate_attestations'
  task remove_duplicate_attestations: :environment do
    dossier_ids = Attestation
      .group(:dossier_id)
      .count
      .filter { |_, attestation_count| attestation_count > 1 }
      .map(&:first)

    dossier_ids.each do |dossier_id|
      current_attestation, *old_attestations = Attestation.where(dossier_id: dossier_id).order(created_at: :desc)

      old_attestations.each do |old|
        if current_attestation.created_at < old.created_at
          raise "something odd, old attestation #{old.id} is newer than the current attestation #{current_attestation.id}"
        end

        old.destroy
      end
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
