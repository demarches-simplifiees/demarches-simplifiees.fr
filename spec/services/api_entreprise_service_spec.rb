describe ApiEntrepriseService do
  describe '#get_etablissement_params_for_siret' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
        .to_return(body: entreprises_body, status: entreprises_status)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
        .to_return(body: etablissements_body, status: etablissements_status)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/.*token=/)
        .to_return(body: exercices_body, status: exercices_status)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/.*token=/)
        .to_return(body: associations_body, status: associations_status)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/effectifs_mensuels_acoss_covid\/#{annee}\/#{mois}\/entreprise\/#{siren}?.*token=/)
        .to_return(body: effectifs_mensuels_body, status: effectifs_mensuels_status)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/effectifs_annuels_acoss_covid\/#{siren}?.*token=/)
        .to_return(body: effectifs_annuels_body, status: effectifs_annuels_status)
    end

    before { Timecop.freeze(Time.zone.local(2020, 3, 14)) }
    after { Timecop.return }

    let(:siren) { '418166096' }
    let(:siret) { '41816609600051' }
    let(:rna) { 'W595001988' }

    let(:entreprises_status) { 200 }
    let(:entreprises_body) { File.read('spec/fixtures/files/api_entreprise/entreprises.json') }

    let(:etablissements_status) { 200 }
    let(:etablissements_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

    let(:effectifs_mensuels_status) { 200 }
    let(:effectifs_mensuels_body) { File.read('spec/fixtures/files/api_entreprise/effectifs.json') }
    let(:annee) { "2020" }
    let(:mois) { "02" }
    let(:effectif_mensuel) { 100.5 }

    let(:effectifs_annuels_status) { 200 }
    let(:effectifs_annuels_body) { File.read('spec/fixtures/files/api_entreprise/effectifs_annuels.json') }
    let(:effectif_annuel) { 100.5 }

    let(:exercices_status) { 200 }
    let(:exercices_body) { File.read('spec/fixtures/files/api_entreprise/exercices.json') }

    let(:associations_status) { 200 }
    let(:associations_body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

    let(:result) { ApiEntrepriseService.get_etablissement_params_for_siret(siret, '1') }

    context 'when service is up' do
      it 'should fetch etablissement params' do
        expect(result[:entreprise_siren]).to eq(siren)
        expect(result[:siret]).to eq(siret)
        expect(result[:association_rna]).to eq(rna)
        expect(result[:exercices_attributes]).to_not be_empty
        expect(result[:entreprise_effectif_mensuel]).to eq(effectif_mensuel)
        expect(result[:entreprise_effectif_annuel]).to eq(effectif_annuel)
      end
    end

    context 'when exercices api down' do
      let(:exercices_status) { 400 }
      let(:exercices_body) { '' }

      it 'should fetch etablissement params' do
        expect(result[:entreprise_siren]).to eq(siren)
        expect(result[:siret]).to eq(siret)
        expect(result[:exercices_attributes]).to be_nil
      end
    end

    context 'when associations api down' do
      let(:associations_status) { 400 }
      let(:associations_body) { '' }

      it 'should fetch etablissement params' do
        expect(result[:entreprise_siren]).to eq(siren)
        expect(result[:siret]).to eq(siret)
        expect(result[:association_rna]).to be_nil
      end
    end

    context 'when entreprise api down' do
      let(:entreprises_status) { 400 }
      let(:entreprises_body) { '' }

      it 'should raise ApiEntreprise::API::RequestFailed' do
        expect { result }.to raise_error(ApiEntreprise::API::RequestFailed)
      end
    end

    context 'when etablissement api down' do
      let(:etablissements_status) { 400 }
      let(:etablissements_body) { '' }

      it 'should raise ApiEntreprise::API::RequestFailed' do
        expect { result }.to raise_error(ApiEntreprise::API::RequestFailed)
      end
    end

    context 'when etablissement not found' do
      let(:etablissements_status) { 404 }
      let(:etablissements_body) { '' }

      it 'should return nil' do
        expect(result).to be_nil
      end
    end

    context 'when entreprise not found' do
      let(:etablissements_status) { 404 }
      let(:etablissements_body) { '' }

      it 'should return nil' do
        expect(result).to be_nil
      end
    end
  end
end
