require 'spec_helper'

describe ApiEntreprise::API do
  let(:procedure_id) { 12 }
  describe '.entreprise' do
    subject { described_class.entreprise(siren, procedure_id) }
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
        .to_return(status: status, body: body)
    end
    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end
    context 'when siret exist' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { File.read('spec/support/files/api_entreprise/entreprises.json') }

      it 'returns response body' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.etablissement' do
    subject { described_class.etablissement(siret, procedure_id) }
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
        .to_return(status: status, body: body)
    end

    context 'when siret does not exist' do
      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'when siret exists' do
      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { File.read('spec/support/files/api_entreprise/etablissements.json') }

      it 'returns body' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.exercices' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/.*token=/)
        .to_return(status: status, body: body)
    end

    context 'when siret does not exist' do
      subject { described_class.exercices(siret, procedure_id) }

      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'when siret exists' do
      subject { described_class.exercices(siret, procedure_id) }

      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { File.read('spec/support/files/api_entreprise/exercices.json') }

      it 'raises RestClient::Unauthorized' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.rna' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/.*token=/)
        .to_return(status: status, body: body)
    end

    subject { described_class.rna(siren, procedure_id) }

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'when siren exists' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { File.read('spec/support/files/api_entreprise/associations.json') }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end
end
