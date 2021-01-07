RSpec.describe 'active_storage initializer' do
  let(:catalogue) { Fog::OpenStack::Auth::Catalog::V3.new({}) }

  describe '#endpoint_url' do
    let(:url) { 'https://default.fr/toto' }

    before { ENV['APPLICATION_BASE_URL'] = 'https://www.ds.fr' }

    subject { catalogue.endpoint_url({ "url" => url }, interface) }

    context 'when the interface is not public' do
      let(:interface) { 'private' }

      it { is_expected.to eq(url) }
    end

    context 'when the interface is public' do
      let(:interface) { 'public' }

      it { is_expected.to eq('https://www.ds.fr/storage/toto') }
    end
  end
end
