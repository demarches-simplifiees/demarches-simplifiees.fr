describe 'shared/dossiers/demande.html.haml', type: :view do
  let(:current_gestionnaire) { create(:gestionnaire) }
  let(:individual) { nil }
  let(:etablissement) { nil }
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure, etablissement: etablissement, individual: individual) }

  before do
    sign_in current_gestionnaire
  end

  subject! { render 'shared/dossiers/demande.html.haml', dossier: dossier, demande_seen_at: nil }

  context 'when dossier was created by an etablissement' do
    let(:etablissement) { create(:etablissement) }

    it 'renders the etablissement infos' do
      expect(rendered).to include(etablissement.entreprise_raison_sociale)
      expect(rendered).to include(etablissement.entreprise_siret_siege_social)
      expect(rendered).to include(etablissement.entreprise_forme_juridique)
    end

    context 'and entreprise is an association' do
      let(:etablissement) { create(:etablissement, :is_association) }

      it 'renders the association infos' do
        expect(rendered).to include(etablissement.association_rna)
        expect(rendered).to include(etablissement.association_titre)
        expect(rendered).to include(etablissement.association_objet)
      end
    end
  end

  context 'when dossier was created by an individual' do
    let(:individual) { create(:individual) }

    it 'renders the individual identity infos' do
      expect(rendered).to include(individual.gender)
      expect(rendered).to include(individual.nom)
      expect(rendered).to include(individual.prenom)
      expect(rendered).to include(individual.birthdate.strftime("%d/%m/%Y"))
    end
  end
end
