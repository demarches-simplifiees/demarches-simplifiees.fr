require 'spec_helper'

describe ApiEntreprise::EntrepriseAdapter do
  let(:siren) { '418166096' }
  let(:procedure_id) { 22 }
  let(:adapter) { described_class.new(siren, procedure_id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
      .to_return(body: File.read('spec/support/files/api_entreprise/entreprises.json', status: 200))
  end

  it '#to_params class est une Hash ?' do
    expect(subject).to be_an_instance_of(Hash)
  end

  context 'Attributs Entreprises' do
    it 'L\'entreprise contient bien un siren' do
      expect(subject[:entreprise_siren]).to eq(siren)
    end

    it 'L\'entreprise contient bien un capital_social' do
      expect(subject[:entreprise_capital_social]).to eq(462308)
    end

    it 'L\'entreprise contient bien un numero_tva_intracommunautaire' do
      expect(subject[:entreprise_numero_tva_intracommunautaire]).to eq('FR16418166096')
    end

    it 'L\'entreprise contient bien une forme_juridique' do
      expect(subject[:entreprise_forme_juridique]).to eq('SA à directoire (s.a.i.)')
    end

    it 'L\'entreprise contient bien un forme_juridique_code' do
      expect(subject[:entreprise_forme_juridique_code]).to eq('5699')
    end

    it 'L\'entreprise contient bien un nom_commercial' do
      expect(subject[:entreprise_nom_commercial]).to eq('OCTO-TECHNOLOGY')
    end

    it 'L\'entreprise contient bien une raison_sociale' do
      expect(subject[:entreprise_raison_sociale]).to eq('OCTO-TECHNOLOGY')
    end

    it 'L\'entreprise contient bien un siret_siege_social' do
      expect(subject[:entreprise_siret_siege_social]).to eq('41816609600051')
    end

    it 'L\'entreprise contient bien un code_effectif_entreprise' do
      expect(subject[:entreprise_code_effectif_entreprise]).to eq('31')
    end

    it 'L\'entreprise contient bien une date_creation' do
      expect(subject[:entreprise_date_creation]).to eq('Wed, 01 Apr 1998 00:00:00.000000000 +0200')
    end

    it 'L\'entreprise contient bien un nom' do
      expect(subject[:entreprise_nom]).to eq('test_nom')
    end

    it 'L\'entreprise contient bien un prenom' do
      expect(subject[:entreprise_prenom]).to eq('test_prenom')
    end
  end
end
