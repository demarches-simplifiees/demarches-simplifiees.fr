class ResetExpiringDossiersJob < ApplicationJob
  def perform(procedure)
    procedure.dossiers
      .where.not(brouillon_close_to_expiration_notice_sent_at: nil)
      .or(Dossier.where.not(en_construction_close_to_expiration_notice_sent_at: nil))
      .or(Dossier.where.not(termine_close_to_expiration_notice_sent_at: nil))
      .in_batches do |relation|
      relation.update_all(brouillon_close_to_expiration_notice_sent_at: nil,
                          en_construction_close_to_expiration_notice_sent_at: nil,
                          termine_close_to_expiration_notice_sent_at: nil)
    end
  end
end
