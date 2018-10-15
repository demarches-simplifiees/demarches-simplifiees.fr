require 'spec_helper'

describe ApiAdresse::PointAdapter do
  let(:address) { '50 av des champs elysees' }

  describe '.geocode', vcr: { cassette_name: 'api_adresse_octo' } do
    it 'return a point' do
      expect(described_class.new(address).geocode.class).to eq(RGeo::Cartesian::PointImpl)
    end
    context 'when RestClient::Exception' do
      before do
        allow(ApiAdresse::API).to receive(:call).and_raise(RestClient::Exception)
      end
      it 'return nil' do
        expect(described_class.new(address).geocode).to be_nil
      end
    end
    context 'when JSON::ParserError' do
      before do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end
      it 'return nil' do
        expect(described_class.new(address).geocode).to be_nil
      end
    end
  end
end
