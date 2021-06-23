describe 'instructeurs/procedures/_download_dossiers.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let(:dossier_count) { 0 }

  subject { render 'instructeurs/procedures/download_dossiers.html.haml', procedure: procedure, dossier_count: dossier_count, exports: {} }

  context "when procedure has 0 dossier" do
    it { is_expected.not_to include("Télécharger tous les dossiers") }
  end

  context "when procedure has at least 1 dossier" do
    let(:dossier_count) { 1 }
    it { is_expected.to include("Télécharger tous les dossiers") }

    context "With zip archive enabled" do
      before { Flipper.enable(:archive_zip_globale, procedure) }
      it { is_expected.to include("Télécharger une archive au format .zip") }
    end

    context "With zip archive disabled" do
      before { Flipper.disable(:archive_zip_globale, procedure) }
      it { is_expected.not_to include("Télécharger une archive au format .zip") }
    end
  end
end
