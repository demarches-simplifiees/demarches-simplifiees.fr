describe DossierSearchableConcern do
  let(:champ_public) { dossier.champs_public.first }
  let(:champ_private) { dossier.champs_private.first }

  subject { dossier }

  describe '#update_search_terms' do
    let(:etablissement) { dossier.etablissement }
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }
    let(:etablissement) { build(:etablissement, entreprise_nom: 'Dupont', entreprise_prenom: 'Thomas', association_rna: '12345', association_titre: 'asso de test', association_objet: 'tests unitaires') }
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
    let(:dossier) { create(:dossier, etablissement: etablissement, user: user, procedure: procedure) }
    let(:france_connect_information) { build(:france_connect_information, given_name: 'Chris', family_name: 'Harrisson') }
    let(:user) { build(:user, france_connect_informations: [france_connect_information]) }

    let(:result) do
      Dossier.connection.execute(
        Dossier.sanitize_sql_array(["SELECT search_terms, private_search_terms FROM dossiers WHERE id = :id", id: dossier.id])
      ).first
    end

    before do
      champ_public.update_attribute(:value, "champ public")
      champ_private.update_attribute(:value, "champ privé")

      perform_enqueued_jobs(only: DossierUpdateSearchTermsJob)
    end

    it "update columns" do
      expect(result["search_terms"]).to eq("#{user.email} champ public #{etablissement.entreprise_siren} #{etablissement.entreprise_numero_tva_intracommunautaire} #{etablissement.entreprise_forme_juridique} #{etablissement.entreprise_forme_juridique_code} #{etablissement.entreprise_nom_commercial} #{etablissement.entreprise_raison_sociale} #{etablissement.entreprise_siret_siege_social} #{etablissement.entreprise_nom} #{etablissement.entreprise_prenom} #{etablissement.association_rna} #{etablissement.association_titre} #{etablissement.association_objet} #{etablissement.siret} #{etablissement.naf} #{etablissement.libelle_naf} #{etablissement.adresse} #{etablissement.code_postal} #{etablissement.localite} #{etablissement.code_insee_localite}")
      expect(result["private_search_terms"]).to eq('champ privé')
    end

    context 'with an update' do
      before do
        dossier.update(
          champs_public_attributes: [{ id: champ_public.id, value: 'nouvelle valeur publique' }],
          champs_private_attributes: [{ id: champ_private.id, value: 'nouvelle valeur privee' }]
        )

        perform_enqueued_jobs(only: DossierUpdateSearchTermsJob)
      end

      it "update columns" do
        expect(result["search_terms"]).to include('nouvelle valeur publique')
        expect(result["private_search_terms"]).to include('nouvelle valeur privee')
      end
    end
  end
end
