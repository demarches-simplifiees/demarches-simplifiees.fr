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
  end
end
