describe 'gestionnaires/dossiers/print.html.haml', type: :view do
  before { view.extend DossierHelper }

  context "with a dossier" do
    let(:current_gestionnaire) { create(:gestionnaire) }
    let(:dossier) { create(:dossier, :en_instruction, :with_commentaires) }

    before do
      assign(:dossier, dossier)
      allow(view).to receive(:current_gestionnaire).and_return(current_gestionnaire)

      render
    end

    it { expect(rendered).to include("Dossier nº #{dossier.id}") }
    it { expect(rendered).to include(dossier.procedure.libelle) }
  end
end
