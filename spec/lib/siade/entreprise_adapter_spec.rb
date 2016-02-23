require 'spec_helper'

describe SIADE::EntrepriseAdapter do
  subject { described_class.new('418166096').to_params }

  before do
    stub_request(:get, "https://apientreprise.fr/api/v1/entreprises/418166096?token=#{SIADETOKEN}")
        .to_return(body: File.read('spec/support/files/entreprise.json', status: 200))
  end

  it '#to_params class est une Hash ?' do
    expect(subject).to be_an_instance_of(Hash)
  end

  context 'Attributs Entreprises' do
    it 'L\'entreprise contient bien un siren' do
      expect(subject[:siren]).to eq('418166096')
    end

    it 'L\'entreprise contient bien un capital_social' do
      expect(subject[:capital_social]).to eq(372_795)
    end

    it 'L\'entreprise contient bien un numero_tva_intracommunautaire' do
      expect(subject[:numero_tva_intracommunautaire]).to eq('FR16418166096')
    end

    it 'L\'entreprise contient bien une forme_juridique' do
      expect(subject[:forme_juridique]).to eq('SA à directoire (s.a.i.)')
    end

    it 'L\'entreprise contient bien un forme_juridique_code' do
      expect(subject[:forme_juridique_code]).to eq('5699')
    end

    it 'L\'entreprise contient bien un nom_commercial' do
      expect(subject[:nom_commercial]).to eq('OCTO-TECHNOLOGY')
    end

    it 'L\'entreprise contient bien une raison_sociale' do
      expect(subject[:raison_sociale]).to eq('OCTO-TECHNOLOGY')
    end

    it 'L\'entreprise contient bien un siret_siege_social' do
      expect(subject[:siret_siege_social]).to eq('41816609600051')
    end

    it 'L\'entreprise contient bien un code_effectif_entreprise' do
      expect(subject[:code_effectif_entreprise]).to eq('22')
    end

    it 'L\'entreprise contient bien une date_creation' do
      expect(subject[:date_creation]).to eq('Mon, 01 Jan 1900 00:00:00.000000000 +0100')
    end

    it 'L\'entreprise contient bien un nom' do
      expect(subject[:nom]).to eq('test_nom')
    end

    it 'L\'entreprise contient bien un prenom' do
      expect(subject[:prenom]).to eq('test_prenom')
    end
  end

  context 'Mandataire sociaux' do
    subject { described_class.new('418166096').mandataires_sociaux }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Array)
    end

    it { expect(subject.size).to eq(8) }

    describe 'Attributs' do
      it 'Un mandataire social possède bien un nom' do
        expect(subject[0][:nom]).to eq('HISQUIN')
      end
      it 'Un mandataire social possède bien un prenom' do
        expect(subject[0][:prenom]).to eq('FRANCOIS')
      end

      it 'Un mandataire social possède bien une fonction' do
        expect(subject[0][:fonction]).to eq('PRESIDENT DU DIRECTOIRE')
      end

      it 'Un mandataire social possède bien une date de naissance' do
        expect(subject[0][:date_naissance]).to eq('1965-01-27')
      end

      it 'Un mandataire social possède bien une date de naissance au format timestamp' do
        expect(subject[0][:date_naissance_timestamp]).to eq(-155523600)
      end
    end
  end
end
