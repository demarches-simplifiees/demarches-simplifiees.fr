require 'spec_helper'

describe SIADE::EntrepriseAdapter do
  subject { SIADE::EntrepriseAdapter.new('418166096').to_params }

  before do
    stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/418166096?token=#{SIADETOKEN}")
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
      expect(subject[:capital_social]).to eq(372795)
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
      expect(subject[:date_creation]).to eq(891381600)
    end

    it 'L\'entreprise contient bien un nom' do
      expect(subject[:nom]).to eq('test_nom')
    end

    it 'L\'entreprise contient bien un prenom' do
      expect(subject[:prenom]).to eq('test_prenom')
    end
  end
end