describe DossierLinkHelper do
  describe "#dossier_linked_path" do
    context "when no access" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:dossier) { create(:dossier) }

      it { expect(helper.dossier_linked_path(gestionnaire, dossier)).to be_nil }
    end

    context "when access as gestionnaire" do
      let(:dossier) { create(:dossier ) }
      let(:gestionnaire) { create(:gestionnaire) }

      before { dossier.procedure.gestionnaires << gestionnaire }

      it { expect(helper.dossier_linked_path(gestionnaire, dossier)).to eq(dossier_path(dossier.procedure, dossier)) }
    end

    context "when access as expert" do
      let(:dossier) { create(:dossier ) }
      let(:gestionnaire) { create(:gestionnaire) }
      let!(:avis) { create(:avis, dossier: dossier, gestionnaire: gestionnaire) }

      it { expect(helper.dossier_linked_path(gestionnaire, dossier)).to eq(avis_path(avis)) }
    end
  end
end
