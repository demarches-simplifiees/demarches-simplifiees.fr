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

  context 'when the dossier has champs' do
    let(:procedure) { create(:procedure, :published, :with_type_de_champ) }

    it 'renders the champs' do
      dossier.champs.each do |champ|
        expect(rendered).to include(champ.libelle)
      end
    end
  end

  context 'when the dossier has pièces justificatives' do
    let(:procedure) { create(:procedure, :published, :with_two_type_de_piece_justificative) }

    it 'renders the pièces justificatives' do
      expect(rendered).to have_text('Pièces jointes')
    end
  end

  context 'when the dossier uses maps' do
    let(:procedure) { create(:procedure, :published, :with_api_carto) }

    it 'renders the maps infos' do
      expect(rendered).to have_text('Cartographie')
    end
  end
end
