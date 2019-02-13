require 'spec_helper'

describe Etablissement do
  describe '#geo_adresse' do
    let(:etablissement) { create(:etablissement) }

    subject { etablissement.geo_adresse }

    it { is_expected.to eq '6 RUE RAOUL NORDLING IMMEUBLE BORA 92270 BOIS COLOMBES' }
  end

  describe '#inline_adresse' do
    let(:etablissement) { create(:etablissement, nom_voie: 'green    moon') }

    it { expect(etablissement.inline_adresse).to eq '6 RUE green moon, IMMEUBLE BORA, 92270 BOIS COLOMBES' }

    context 'with missing complement adresse' do
      let(:etablissement) { create(:etablissement, complement_adresse: '') }

      it { expect(etablissement.inline_adresse).to eq '6 RUE RAOUL NORDLING, 92270 BOIS COLOMBES' }
    end
  end

  describe '#verify' do
    let(:etablissement) { create(:etablissement) }
    let(:etablissement2) { create(:etablissement) }

    it 'should verify signed etablissement' do
      etablissement.signature = etablissement.sign
      expect(etablissement.verify).to eq(true)
    end

    it 'should reject etablissement with other etablissement signature' do
      etablissement.signature = etablissement2.sign
      expect(etablissement.verify).to eq(false)
    end

    it 'should reject etablissement with wrong signature' do
      etablissement.signature = "fd7687fdsgdf6gd7f8g"
      expect(etablissement.verify).to eq(false)
    end
  end
end
