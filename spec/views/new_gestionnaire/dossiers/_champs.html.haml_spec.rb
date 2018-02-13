describe 'new_gestionnaire/dossiers/champs.html.haml', type: :view do
  let(:gestionnaire) { create(:gestionnaire) }
  let(:demande_seen_at) { nil }

  before do
    view.extend DossierHelper
    view.extend DossierLinkHelper
    allow(view).to receive(:current_gestionnaire).and_return(gestionnaire)
  end

  subject { render 'new_gestionnaire/dossiers/champs.html.haml', champs: champs, demande_seen_at: demande_seen_at }

  context "there are some champs" do
    let(:dossier) { create(:dossier) }
    let(:avis) { create :avis, dossier: dossier, gestionnaire: gestionnaire }
    let(:champ1) { create(:champ, :checkbox, value: "on") }
    let(:champ2) { create(:champ, :header_section, value: "Section") }
    let(:champ3) { create(:champ, :explication, value: "mazette") }
    let(:champ4) { create(:champ, :dossier_link, value: dossier.id) }
    let(:champs) { [champ1, champ2, champ3, champ4] }

    before { dossier.avis << avis }

    it { is_expected.to include(champ1.libelle) }
    it { is_expected.to include(champ1.value) }

    it { is_expected.to have_css(".header-section") }
    it { is_expected.to include(champ2.libelle) }

    it { is_expected.not_to include(champ3.libelle) }
    it { is_expected.not_to include(champ3.value) }

    it { is_expected.to have_link("Dossier nº #{dossier.id}") }
    it { is_expected.to include(dossier.text_summary) }
  end

  context "with a dossier champ, but we are not authorized to acces the dossier" do
    let(:dossier) { create(:dossier) }
    let(:champ) { create(:champ, :dossier_link, value: dossier.id) }
    let(:champs) { [champ] }

    it { is_expected.not_to have_link("Dossier nº #{dossier.id}") }
    it { is_expected.to include("Dossier nº #{dossier.id}") }
    it { is_expected.to include(dossier.text_summary) }
  end

  context "with a dossier_link champ but without value" do
    let(:champ) { create(:champ, :dossier_link, value: nil) }
    let(:champs) { [champ] }

    it { is_expected.to include("Pas de dossier associé") }
  end

  context "with seen_at" do
    let(:dossier) { create(:dossier) }
    let(:champ1) { create(:champ, :checkbox, value: "on") }
    let(:champs) { [champ1] }

    context "with a demande_seen_at after champ updated_at" do
      let(:demande_seen_at) { champ1.updated_at + 1.hour }

      it { is_expected.not_to have_css(".highlighted") }
    end

    context "with a demande_seen_at after champ updated_at" do
      let(:demande_seen_at) { champ1.updated_at - 1.hour }

      it { is_expected.to have_css(".highlighted") }
    end
  end
end
