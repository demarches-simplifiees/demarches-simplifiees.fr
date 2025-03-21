# frozen_string_literal: true

describe Rdv do
  describe '.pending_for_instructeur' do
    let(:instructeur1) { create(:instructeur) }
    let(:instructeur2) { create(:instructeur) }
    let(:dossier) { create(:dossier) }

    let!(:pending_rdv_for_instructeur1) { create(:rdv, instructeur: instructeur1, dossier: dossier, rdv_external_id: nil) }
    let!(:booked_rdv_for_instructeur1) { create(:rdv, instructeur: instructeur1, dossier: dossier, rdv_external_id: 'external-id-123') }
    let!(:pending_rdv_for_instructeur2) { create(:rdv, instructeur: instructeur2, dossier: dossier, rdv_external_id: nil) }

    subject { Rdv.pending_for_instructeur(instructeur1) }

    it 'returns only pending RDVs for the specified instructeur' do
      expect(subject).to include(pending_rdv_for_instructeur1)
      expect(subject).not_to include(booked_rdv_for_instructeur1)
      expect(subject).not_to include(pending_rdv_for_instructeur2)
    end
  end
end
