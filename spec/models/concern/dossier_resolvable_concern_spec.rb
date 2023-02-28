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
end
