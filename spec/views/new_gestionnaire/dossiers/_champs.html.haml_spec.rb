describe 'new_gestionnaire/dossiers/champs.html.haml', type: :view do
  before { render 'new_gestionnaire/dossiers/champs.html.haml', champs: champs }

  context "there are some champs" do
    let(:dossier) { create(:dossier) }
    let(:champ1) { create(:champ, :checkbox, value: "true") }
    let(:champ2) { create(:champ, :header_section, value: "Section") }
    let(:champ3) { create(:champ, :explication, value: "mazette") }
    let(:champ4) { create(:champ, :dossier_link, value: dossier.id) }
    let(:champs) { [champ1, champ2, champ3, champ4] }

    it { expect(rendered).to include(champ1.libelle) }
    it { expect(rendered).to include(champ1.for_displaying) }

    it { expect(rendered).to have_css(".header-section") }
    it { expect(rendered).to include(champ2.libelle) }

    it { expect(rendered).not_to include(champ3.libelle) }
    it { expect(rendered).not_to include(champ3.for_displaying) }

    it { expect(rendered).to have_link("Dossier nº #{dossier.id}") }
    it { expect(rendered).to include(dossier.text_summary) }
  end

  context "with a dossier_link champ but without value" do
    let(:champ) { create(:champ, :dossier_link, value: nil) }
    let(:champs) { [champ] }

    it { expect(rendered).to include("Pas de dossier associé") }
  end
end
