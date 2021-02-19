describe APIAddress::AddressAdapter do
  let(:search_term) { 'Paris' }
  let(:adapter) { described_class.new(search_term) }
  subject { adapter.to_params }

  before do
    Geocoder.configure(lookup: :ban_data_gouv_fr, use_https: true)
    stub_request(:get, /https:\/\/api-adresse.data.gouv.fr\/search/)
      .to_return(body: body, status: status)
  end

  after do
    Geocoder.configure(lookup: :test)
  end

  context "when responds with valid schema" do
    let(:body) { File.read('spec/fixtures/files/api_address/address.json') }
    let(:status) { 200 }

    it '#to_params returns a valid' do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject[:city_name]).to eq(search_term)
      expect(subject[:city_code]).to eq('75056')
    end
  end

  context "when responds with an address which is not a direct match to search term" do
    let(:body) { File.read('spec/fixtures/files/api_address/address.json') }
    let(:status) { 200 }
    let(:search_term) { 'Lyon' }

    it '#to_params ignores the response' do
      expect(subject).to be_nil
    end
  end

  context "when responds with invalid schema" do
    let(:body) { File.read('spec/fixtures/files/api_address/address_invalid.json') }
    let(:status) { 200 }

    it '#to_params raise exception' do
      expect { subject }.to raise_exception(APIAddress::AddressAdapter::InvalidSchemaError)
    end
  end
end
