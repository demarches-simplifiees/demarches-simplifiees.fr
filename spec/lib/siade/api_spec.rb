require 'spec_helper'

describe SIADE::API do
  describe '.entreprise' do
    subject { described_class.entreprise(siren) }
    before do
      stub_request(:get, "https://apientreprise.fr/api/v1/entreprises/#{siren}?token=#{SIADETOKEN}")
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
      let(:body) { File.read('spec/support/files/entreprise.json') }

      it 'returns response body' do
        expect(subject).to eq(body)
      end
    end
  end

  describe '.etablissement' do
    subject { described_class.etablissement(siret) }
    before do
      stub_request(:get, "https://apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}")
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
      let(:body) { File.read('spec/support/files/etablissement.json') }

      it 'returns body' do
        expect(subject).to eq(body)
      end
    end
  end

  describe '.exercices' do
    before do
      stub_request(:get, /https:\/\/apientreprise.fr\/api\/v1\/etablissements\/exercices\/.*token=/)
          .to_return(status: status, body: body)
    end

    context 'when siret does not exist' do
      subject { described_class.exercices(siret) }

      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises RestClient::ResourceNotFound' do
        expect { subject }.to raise_error(RestClient::ResourceNotFound)
      end
    end

    context 'when siret exists' do
      subject { described_class.exercices(siret) }

      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { File.read('spec/support/files/exercices.json') }

      it 'raises RestClient::Unauthorized' do
        expect(subject).to eq(body)
      end
    end
  end

  describe '.rna' do
    before do
      stub_request(:get, /https:\/\/apientreprise.fr\/api\/v1\/associations\/.*token=/)
          .to_return(status: status, body: body)
    end

    subject { described_class.rna(siren) }

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
      let(:body) { File.read('spec/support/files/rna.json') }

      it{ expect(subject).to eq(body) }
    end
  end
end
