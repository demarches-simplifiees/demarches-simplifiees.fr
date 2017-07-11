describe 'new_gestionnaire/dossiers/champs.html.haml', type: :view do
  before { render 'new_gestionnaire/dossiers/champs.html.haml', champs: champs }

  context "there is some champs" do
    let(:champ1) { create(:champ, :checkbox, value: "true") }
    let(:champ2) { create(:champ, :header_section, value: "Section") }
    let(:champs) { [champ1, champ2] }

    it { expect(rendered).to include(champ1.libelle) }
    it { expect(rendered).to include(champ1.value) }

    it { expect(rendered).to have_css(".header-section") }
    it { expect(rendered).to include(champ2.libelle) }
  end
end
