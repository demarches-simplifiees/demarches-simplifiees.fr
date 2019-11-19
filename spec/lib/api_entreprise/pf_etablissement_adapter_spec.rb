require 'spec_helper'

describe ApiEntreprise::PfEtablissementAdapter do
  let(:procedure_id) { 33 }

  context 'Numéro TAHITI valide', vcr: { cassette_name: 'pf_api_entreprise' } do
    let(:siret) { '075390' }
    subject { described_class.new(siret, procedure_id).to_params }

    it 'L\'entreprise contient bien les bons renseignements' do
      expect(subject).to be_a_instance_of(Hash)
      expect(subject[:siret]).to eq(siret)
      expect(subject[:naf]).to eq('6419Z')
      expect(subject[:libelle_naf]).to eq('Autres intermédiations monétaires')
      expect(subject[:adresse]).to eq("BP 130, 98713 PAPEETE BP,\n115,\nrue Dumont d'Urville,\nquartier Orovini,\nPapeete")
      expect(subject[:numero_voie]).to eq('115')
      expect(subject[:nom_voie]).to eq("rue Dumont d'Urville")
      expect(subject[:code_postal]).to eq('98713')
      expect(subject[:localite]).to eq('Papeete')
    end
  end

  context 'when siret is not found', vcr: { cassette_name: 'pf_api_entreprise_not_found' } do
    let(:bad_siret) { 111111 }
    subject { described_class.new(bad_siret, 12).to_params }

    it { expect(subject).to eq({}) }
  end
end
