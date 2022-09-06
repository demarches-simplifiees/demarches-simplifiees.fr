describe APIEntreprise::ServiceAdapter do
  before do
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  let(:siret) { '41816609600051' }
  let(:service) { create(:service, siret: siret) }

  context 'SIRET valide avec infos diffusables' do
    let(:fixture) { 'spec/fixtures/files/api_entreprise/etablissements.json' }
    subject { described_class.new(siret, service.id).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}/)
        .with(query: hash_including({ 'object' => "service_id: #{service.id}" }))
        .to_return(body: File.read(fixture, status: 200))
    end

    it '#to_params class est une Hash ?' do
      expect(subject).to be_a_instance_of(Hash)
    end

    context 'Attributs Etablissements' do
      it 'should contains a SIRET' do
        expect(subject[:siret]).to eq(siret)
      end

      it 'should not return siege_social information' do
        expect(subject[:siege_social]).to be_nil
      end

      context 'Concaténation lignes adresse' do
        it 'service contains a multi lines adress' do
          expect(subject[:adresse]).to eq("OCTO TECHNOLOGY\r\n50 AVENUE DES CHAMPS ELYSEES\r\n75008 PARIS\r\nFRANCE")
        end
      end

      context 'adress details' do
        it 'service contains a numero_voie' do
          expect(subject[:numero_voie]).to eq('50')
        end

        it 'service contains a type_voie' do
          expect(subject[:type_voie]).to eq('AV')
        end

        it 'service contains a nom_voie' do
          expect(subject[:nom_voie]).to eq('DES CHAMPS ELYSEES')
        end
        it 'service contains a complement_adresse' do
          expect(subject[:complement_adresse]).to eq('complement_adresse')
        end

        it 'service contains a code_postal' do
          expect(subject[:code_postal]).to eq('75008')
        end

        it 'service contains a localite' do
          expect(subject[:localite]).to eq('PARIS 8')
        end

        it 'service contains a code_insee_localite' do
          expect(subject[:code_insee_localite]).to eq('75108')
        end
      end
    end

    context 'Attributs Etablissements pour etablissement non siege' do
      let(:siret) { '17310120500719' }
      let(:fixture) { 'spec/fixtures/files/api_entreprise/etablissements-non-siege.json' }
      it 'service contains a siret' do
        expect(subject[:siret]).to eq(siret)
      end
    end
  end

  context 'when siret is not found' do
    let(:bad_siret) { 11_111_111_111_111 }
    subject { described_class.new(bad_siret, service.id).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{bad_siret}/)
        .with(query: hash_including({ 'object' => "service_id: #{service.id}" }))
        .to_return(body: 'Fake body', status: 404)
    end

    it { expect(subject).to eq({}) }
  end
end
