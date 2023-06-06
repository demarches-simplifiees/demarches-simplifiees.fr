describe DossierCorrectableConcern do
  describe "#pending_correction?" do
    let(:dossier) { create(:dossier, :en_construction) }

    context "when dossier has no correction" do
      it { expect(dossier.pending_correction?).to be_falsey }
    end

    context "when dossier has a pending correction" do
      before { create(:dossier_correction, dossier:) }

      it { expect(dossier.pending_correction?).to be_truthy }
    end

    context "when dossier has a resolved correction" do
      before { create(:dossier_correction, :resolved, dossier:) }

      it { expect(dossier.pending_correction?).to be_falsey }
    end

    context "when dossier is not en_construction" do
      let(:dossier) { create(:dossier, :en_instruction) }
      before { create(:dossier_correction, dossier:) }

      it { expect(dossier.pending_correction?).to be_falsey }
    end
  end

  describe '#flag_as_pending_correction!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:instructeur) { create(:instructeur) }
    let(:commentaire) { create(:commentaire, dossier:, instructeur:) }

    context 'when dossier is en_construction' do
      it 'creates a correction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.corrections.pending.count }.by(1)
      end

      it 'does not change dossier state' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.not_to change { dossier.state }
      end
    end

    context 'when dossier is en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it 'creates a correction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.corrections.pending.count }.by(1)
      end

      it 'repasse dossier en_construction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.state }.to('en_construction')
      end
    end

    context 'when dossier has already a pending correction' do
      before { create(:dossier_correction, dossier:) }

      it 'does not create a correction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.not_to change { dossier.corrections.pending.count }
      end
    end

    context 'when dossier has already a resolved correction' do
      before { create(:dossier_correction, :resolved, dossier:) }

      it 'creates a correction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.corrections.pending.count }.by(1)
      end
    end

    context 'when dossier is not en_construction and may not be repassed en_construction' do
      let(:dossier) { create(:dossier, :accepte) }

      it 'does not create a correction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.not_to change { dossier.corrections.pending.count }
      end
    end

    context 'when procedure is sva' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: create(:procedure, :published, :sva)) }

      it 'creates a correction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.corrections.pending.count }.by(1)
      end

      it 'repasse dossier en_construction' do
        expect { dossier.flag_as_pending_correction!(commentaire) }.to change { dossier.state }.to('en_construction')
      end
    end
  end

  describe "#resolve_pending_correction!" do
    let(:dossier) { create(:dossier, :en_construction) }

    subject(:resolve) { dossier.resolve_pending_correction! }
    context "when dossier has no correction" do
      it { expect { resolve }.not_to change { dossier.corrections.pending.count } }
    end

    context "when dossier has a pending correction" do
      let!(:correction) { create(:dossier_correction, dossier:) }

      it {
        expect { resolve }.to change { correction.reload.resolved_at }.from(nil)
      }
    end

    context "when dossier has a already resolved correction" do
      before { create(:dossier_correction, :resolved, dossier:) }

      it { expect { resolve }.not_to change { dossier.corrections.pending.count } }
    end
  end
end
