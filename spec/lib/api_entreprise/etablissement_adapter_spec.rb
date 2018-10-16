require 'spec_helper'

describe ApiEntreprise::EtablissementAdapter do
  let(:procedure_id) { 33 }

  context 'SIRET valide' do
    let(:siret) { '41816609600051' }
    subject { described_class.new(siret, procedure_id).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
        .to_return(body: File.read('spec/fixtures/files/api_entreprise/etablissements.json', status: 200))
    end

    it '#to_params class est une Hash ?' do
      expect(subject).to be_a_instance_of(Hash)
    end

    context 'Attributs Etablissements' do
      it 'L\'entreprise contient bien un siret' do
        expect(subject[:siret]).to eq(siret)
      end

      it 'L\'entreprise contient bien un siege_social' do
        expect(subject[:siege_social]).to eq(true)
      end

      it 'L\'entreprise contient bien un naf' do
        expect(subject[:naf]).to eq('6202A')
      end

      it 'L\'entreprise contient bien un libelle_naf' do
        expect(subject[:libelle_naf]).to eq('Conseil en systèmes et logiciels informatiques')
      end

      context 'Concaténation lignes adresse' do
        it 'L\'entreprise contient bien une adresse sur plusieurs lignes' do
          expect(subject[:adresse]).to eq("OCTO TECHNOLOGY\r\n50 AVENUE DES CHAMPS ELYSEES\r\n75008 PARIS\r\nFRANCE")
        end
      end

      context 'Détails adresse' do
        it 'L\'entreprise contient bien un numero_voie' do
          expect(subject[:numero_voie]).to eq('50')
        end

        it 'L\'entreprise contient bien un type_voie' do
          expect(subject[:type_voie]).to eq('AV')
        end

        it 'L\'entreprise contient bien un nom_voie' do
          expect(subject[:nom_voie]).to eq('DES CHAMPS ELYSEES')
        end
        it 'L\'entreprise contient bien un complement_adresse' do
          expect(subject[:complement_adresse]).to eq('complement_adresse')
        end

        it 'L\'entreprise contient bien un code_postal' do
          expect(subject[:code_postal]).to eq('75008')
        end

        it 'L\'entreprise contient bien une localite' do
          expect(subject[:localite]).to eq('PARIS 8')
        end

        it 'L\'entreprise contient bien un code_insee_localite' do
          expect(subject[:code_insee_localite]).to eq('75108')
        end
      end
    end
  end

  context 'when siret is not found' do
    let(:bad_siret) { 11_111_111_111_111 }
    subject { described_class.new(bad_siret, 12).to_params }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{bad_siret}?.*token=/)
        .to_return(body: 'Fake body', status: 404)
    end

    it { expect(subject).to eq({}) }
  end
end
