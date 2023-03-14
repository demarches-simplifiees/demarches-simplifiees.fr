describe DossierResolvableConcern do
  describe "#pending_resolution?" do
    let(:dossier) { create(:dossier, :en_construction) }

    context "when dossier has no resolution" do
      it { expect(dossier.pending_resolution?).to be_falsey }
    end

    context "when dossier has a pending resolution" do
      before { create(:dossier_resolution, dossier:) }

      it { expect(dossier.pending_resolution?).to be_truthy }
    end

    context "when dossier has a resolved resolution" do
      before { create(:dossier_resolution, :resolved, dossier:) }

      it { expect(dossier.pending_resolution?).to be_falsey }
    end

    context "when dossier is not en_construction" do
      let(:dossier) { create(:dossier, :en_instruction) }
      before { create(:dossier_resolution, dossier:) }

      it { expect(dossier.pending_resolution?).to be_falsey }
    end
  end

  describe '#flag_as_pending_correction!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:instructeur) { create(:instructeur) }
    let(:commentaire) { create(:commentaire, dossier:, instructeur:) }

    context 'when dossier is en_construction' do
      it 'creates a resolution' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.resolutions.pending.count }.by(1)
      end

      it 'does not change dossier state' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.not_to change { dossier.state }
      end
    end

    context 'when dossier is not en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it 'creates a resolution' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.resolutions.pending.count }.by(1)
      end

      it 'repasse dossier en_construction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.state }.to('en_construction')
      end
    end

    context 'when dossier has already a pending resolution' do
      before { create(:dossier_resolution, dossier:) }

      it 'does not create a resolution' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.not_to change { dossier.resolutions.pending.count }
      end
    end

    context 'when dossier has already a resolved resolution' do
      before { create(:dossier_resolution, :resolved, dossier:) }

      it 'creates a resolution' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.resolutions.pending.count }.by(1)
      end
    end

    context 'when dossier is not en_construction and may not be repassed en_construction' do
      let(:dossier) { create(:dossier, :accepte) }

      it 'does not create a resolution' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.not_to change { dossier.resolutions.pending.count }
      end
    end
  end
end
