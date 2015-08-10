require 'spec_helper'

describe SIADE::EntrepriseAdapter do

  context 'self.#entreprise bad SIREN' do
    let(:siren){1}
    subject { SIADE::Api.entreprise(siren) }

    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/#{siren}?token=#{SIADETOKEN}").
          to_return(:status => 404, :body => "", :headers => {})
    end

    it 'bad SIREN' do
      expect(subject).to eq(nil)
    end
  end

  context 'self.#etablissement bad SIRET' do
    let(:siret){1}
    subject { SIADE::Api.etablissement(siret) }

    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}").
          to_return(:status => 404, :body => "", :headers => {})
    end

    it 'bad SIRET' do
      expect(subject).to eq(nil)
    end
  end
end