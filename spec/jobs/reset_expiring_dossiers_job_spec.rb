# frozen_string_literal: true

describe ResetExpiringDossiersJob do
  subject { described_class.new(procedure).perform_now }
  let(:duree_conservation_dossiers_dans_ds) { 2 }
  let(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds:) }

  describe '.perform_now' do
    it 'resets flags' do
      expiring_dossier_brouillon = create(:dossier, :brouillon, procedure: procedure, brouillon_close_to_expiration_notice_sent_at: duree_conservation_dossiers_dans_ds.months.ago)
      expiring_dossier_en_construction = create(:dossier, :en_construction, procedure: procedure, en_construction_close_to_expiration_notice_sent_at: duree_conservation_dossiers_dans_ds.months.ago)
      expiring_dossier_en_termine = create(:dossier, :accepte, procedure: procedure, termine_close_to_expiration_notice_sent_at: duree_conservation_dossiers_dans_ds.months.ago)

      subject

      expect(expiring_dossier_brouillon.reload.brouillon_close_to_expiration_notice_sent_at).to eq(nil)
      expect(expiring_dossier_en_construction.reload.en_construction_close_to_expiration_notice_sent_at).to eq(nil)
      expect(expiring_dossier_en_termine.reload.termine_close_to_expiration_notice_sent_at).to eq(nil)
      expect(expiring_dossier_brouillon.expired_at).to be_within(1.hour).of(2.months.from_now)
      expect(expiring_dossier_en_construction.expired_at).to be_within(1.hour).of(2.months.from_now)
      expect(expiring_dossier_en_termine.expired_at).to be_within(1.hour).of(2.months.from_now)
    end
  end
end
