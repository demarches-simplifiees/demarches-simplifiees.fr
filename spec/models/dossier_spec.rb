require 'spec_helper'

describe Dossier do
  let(:dossier) { create(:dossier, :with_entreprise) }

  let(:entreprise) { dossier.entreprise }
  let(:etablissement) { dossier.etablissement }

  subject { dossier }

  describe '#siren' do
    it 'returns entreprise siren' do
      expect(subject.siren).to eq(entreprise.siren)
    end
  end

  describe '#siret' do
    it 'returns etablissement siret' do
      expect(subject.siret).to eq(etablissement.siret)
    end
  end

  describe '#liste_piece_justificative' do
    subject { dossier.liste_piece_justificative }
    it 'returns list of required piece justificative' do
      expect(subject.size).to eq(7)
      expect(subject).to include(23)
    end
  end
end