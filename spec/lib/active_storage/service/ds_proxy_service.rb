describe ActiveStorage::Service::DsProxyService do
  let(:private_host) { 'storage.sbg1.cloud.ovh.net:443' }
  let(:public_host) { 'static.demarches-simplifiees.fr' }
  let(:auth) { 'AUTH_a24c37ed11a84896914514384898c34b' }
  let(:bucket) { 'test_local' }
  let(:key) { '2R6rr89nFeSRkSgXHd3smvEf' }
  let(:temp_url_params) { 'temp_url_sig=5ab8cfc3ba5da2598a6c88cc6b1b461fe4e115bc&temp_url_expires=1547598179' }

  let(:storage_service) { storage_service = double(ActiveStorage::Service) }
  subject { ActiveStorage::Service::DsProxyService.new(wrapped: storage_service) }

  describe '#url' do
    let(:private_url) { "https://#{private_host}/v1/#{auth}/#{bucket}/#{key}?#{temp_url_params}" }
    let(:public_url) { "https://#{public_host}/#{bucket}/#{key}?#{temp_url_params}" }

    before do
      expect(storage_service).to receive(:url).and_return(private_url)
    end

    it 'rewrites the host and removes the "v1/auth..." prefix of the storage URL' do
      expect(subject.url(key)).to eq(public_url)
    end
  end

  describe '#url_for_direct_upload' do
    let(:download_params) { 'inline&filename=documents_top_confidentiels.bmp' }
    let(:private_url) { "https://#{private_host}/v1/#{auth}/#{bucket}/#{key}?#{temp_url_params}&#{download_params}" }
    let(:public_url) { "https://#{public_host}/#{bucket}/#{key}?#{temp_url_params}&#{download_params}" }

    before do
      expect(storage_service).to receive(:url_for_direct_upload).and_return(private_url)
    end

    it 'rewrites the host and removes the "v1/auth..." prefix of the storage URL' do
      expect(subject.url_for_direct_upload(key)).to eq(public_url)
    end
  end
end
