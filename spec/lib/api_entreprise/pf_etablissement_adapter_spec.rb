require 'spec_helper'

describe ApiEntreprise::PfEtablissementAdapter do
  let(:procedure_id) { 33 }

  context 'Numéro TAHITI valide' do
    let(:siret) { '075390' }
    subject { described_class.new(siret, procedure_id).to_params }

    before do
      stub_request(:get, /https:\/\/ppr.api.i-taiete2.gov.pf\/api\/v2\/etablissementsEntreprise.*#{siret}.*/)
        .to_return(body: File.read('spec/fixtures/files/api_entreprise/pf_etablissements.json', status: 200))
    end

    it '#to_params class est une Hash ?' do
      expect(subject).to be_a_instance_of(Hash)
    end

    context 'Attributs Etablissements' do
      it 'L\'entreprise contient bien un numero TAHITI (siret)' do
        expect(subject[:siret]).to eq(siret)
      end

      it 'L\'entreprise contient bien un naf' do
        expect(subject[:naf]).to eq('6419Z')
      end

      it 'L\'entreprise contient bien un libelle_naf' do
        expect(subject[:libelle_naf]).to eq('Autres intermédiations monétaires')
      end

      context 'Concaténation lignes adresse' do
        it 'L\'entreprise contient une adresse sur plusieurs lignes' do
          expect(subject[:adresse]).to eq("115\r\nrue Dumont d'Urville\r\nquartier Orovini\r\nPapeete")
        end
      end

      context 'Détails adresse' do
        it 'L\'entreprise contient bien un numero_voie' do
          expect(subject[:numero_voie]).to eq('115')
        end

        it 'L\'entreprise contient bien un nom_voie' do
          expect(subject[:nom_voie]).to eq("rue Dumont d'Urville")
        end

        it 'L\'entreprise contient bien un code_postal' do
          expect(subject[:code_postal]).to eq('98713')
        end

        it 'L\'entreprise contient bien une localite' do
          expect(subject[:localite]).to eq('PAPEETE BP')
        end
      end
    end
  end

  context 'when siret is not found' do
    let(:bad_siret) { 111111 }
    subject { described_class.new(bad_siret, 12).to_params }

    before do
      stub_request(:get, /https:\/\/ppr.api.i-taiete2.gov.pf\/api\/v2\/etablissementsEntreprise.*#{bad_siret}/)
        .to_return(body: '[]', status: 200)
    end

    it { expect(subject).to eq({}) }
  end
end
