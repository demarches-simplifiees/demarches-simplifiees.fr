# frozen_string_literal: true

class ResetExpiringDossiersJob < ApplicationJob
  queue_as :low
  def perform(procedure)
    procedure
      .dossiers
      .in_batches do |relation|
      relation.each do |dossier|
        if dossier.expiration_started?
          dossier.update(brouillon_close_to_expiration_notice_sent_at: nil,
                        en_construction_close_to_expiration_notice_sent_at: nil,
                        termine_close_to_expiration_notice_sent_at: nil)
          dossier.update_expired_at
        end
      end
    end
  end
end
