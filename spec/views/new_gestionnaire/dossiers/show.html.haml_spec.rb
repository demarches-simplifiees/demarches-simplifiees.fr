describe 'new_gestionnaire/dossiers/show.html.haml', type: :view do
  before { view.extend DossierHelper }

  let(:current_gestionnaire) { create(:gestionnaire) }
  let(:individual) { nil }
  let(:entreprise) { nil }
  let(:dossier) { create(:dossier, :en_construction, entreprise: entreprise, individual: individual) }

  before do
    assign(:dossier, dossier)
    view.stub(:current_gestionnaire).and_return(current_gestionnaire)
    render
  end

  context "when dossier was created by an entreprise" do
    let(:entreprise) { create(:entreprise) }

    it { expect(rendered).to include(entreprise.decorate.raison_sociale_or_name) }
    it { expect(rendered).to include(entreprise.decorate.siret_siege_social) }
    it { expect(rendered).to include(entreprise.decorate.forme_juridique) }

    context "and entreprise is an association" do
      let(:entreprise) { create(:entreprise, :is_association) }

      it { expect(rendered).to include(entreprise.rna_information.association_id) }
      it { expect(rendered).to include(entreprise.rna_information.titre) }
      it { expect(rendered).to include(entreprise.rna_information.objet) }
    end
  end

  context "when dossier was created by an individual" do
    let(:individual) { create(:individual) }

    it { expect(rendered).to include(individual.gender) }
    it { expect(rendered).to include(individual.nom) }
    it { expect(rendered).to include(individual.prenom) }
    it { expect(rendered).to include(Date.parse(individual.birthdate).strftime("%d/%m/%Y")) }
  end
end
