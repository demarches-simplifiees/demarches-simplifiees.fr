describe 'new_gestionnaire/procedures/_download_dossiers.html.haml', type: :view do
  let(:current_gestionnaire) { create(:gestionnaire) }
  let(:procedure) { create(:procedure) }

  subject { render 'new_gestionnaire/procedures/download_dossiers.html.haml', procedure: procedure }

  context "when procedure has 0 dossier" do
    it { is_expected.not_to include("Télécharger tous les dossiers") }
  end

  context "when procedure has 1 dossier brouillon" do
    let!(:dossier) { create(:dossier, procedure: procedure) }
    it { is_expected.not_to include("Télécharger tous les dossiers") }
  end

  context "when procedure has at least 1 dossier en construction" do
    let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    it { is_expected.to include("Télécharger tous les dossiers") }
  end
end
