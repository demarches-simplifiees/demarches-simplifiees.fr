require 'spec_helper'

describe ApiAdresse::Geocodeur do
  let(:address) { '50 av des champs elysees' }
  describe '.convert_adresse_to_point', vcr: { cassette_name: 'api_adresse_octo' } do
    it 'return a point' do
      expect(described_class.convert_adresse_to_point(address).class).to eq(RGeo::Cartesian::PointImpl)
    end
    context 'when RestClient::Exception' do
      before do
        allow_any_instance_of(ApiAdresse::API).to receive(:call).and_raise(RestClient::Exception)
      end
      it 'return nil' do
        expect(described_class.convert_adresse_to_point(address)).to be_nil
      end
    end
    context 'when JSON::ParserError' do
      before do
        allow_any_instance_of(ApiAdresse::PointRetriever).to receive(:point).and_raise(JSON::ParserError)
      end
      it 'return nil' do
        expect(described_class.convert_adresse_to_point(address)).to be_nil
      end
    end
  end
end
