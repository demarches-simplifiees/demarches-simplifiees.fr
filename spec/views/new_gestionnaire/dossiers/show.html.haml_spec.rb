describe 'new_gestionnaire/dossiers/show.html.haml', type: :view do
  before { view.extend DossierHelper }

  let(:current_gestionnaire) { create(:gestionnaire) }
  let(:individual) { nil }
  let(:etablissement) { nil }
  let(:dossier) { create(:dossier, :en_construction, etablissement: etablissement, individual: individual) }

  before do
    assign(:dossier, dossier)
    allow(view).to receive(:current_gestionnaire).and_return(current_gestionnaire)
    render
  end

  context "when dossier was created by an etablissement" do
    let(:etablissement) { create(:etablissement) }

    it { expect(rendered).to include(etablissement.entreprise_raison_sociale) }
    it { expect(rendered).to include(etablissement.entreprise_siret_siege_social) }
    it { expect(rendered).to include(etablissement.entreprise_forme_juridique) }

    context "and entreprise is an association" do
      let(:etablissement) { create(:etablissement, :is_association) }

      it { expect(rendered).to include(etablissement.association_rna) }
      it { expect(rendered).to include(etablissement.association_titre) }
      it { expect(rendered).to include(etablissement.association_objet) }
    end
  end

  context "when dossier was created by an individual" do
    let(:individual) { create(:individual) }

    it { expect(rendered).to include(individual.gender) }
    it { expect(rendered).to include(individual.nom) }
    it { expect(rendered).to include(individual.prenom) }
    it { expect(rendered).to include(individual.birthdate.strftime("%d/%m/%Y")) }
  end
end
