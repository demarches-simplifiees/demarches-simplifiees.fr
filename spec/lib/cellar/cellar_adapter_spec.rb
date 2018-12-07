describe 'CellarAdapter' do
  let(:session) { Cellar::CellarAdapter::Session.new(nil, nil) }

  before { Timecop.freeze(Time.gm(2016, 10, 2)) }
  after { Timecop.return }

  describe 'add_range_header' do
    let(:request) { Net::HTTP::Get.new('/whatever') }

    before { session.send(:add_range_header, request, range) }

    subject { request['range'] }

    context 'with end included' do
      let(:range) { 100..500 }

      it { is_expected.to eq('bytes=100-500') }
    end

    context 'with end excluded' do
      let(:range) { 10...50 }

      it { is_expected.to eq('bytes=10-49') }
    end
  end

  describe 'parse_bucket_listing' do
    let(:response) do
      <<~EOS
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>example-bucket</Name>
          <Prefix></Prefix>
          <KeyCount>2</KeyCount>
          <MaxKeys>1000</MaxKeys>
          <Delimiter>/</Delimiter>
          <IsTruncated>false</IsTruncated>
          <Contents>
            <Key>sample1.jpg</Key>
            <LastModified>2011-02-26T01:56:20.000Z</LastModified>
            <ETag>&quot;bf1d737a4d46a19f3bced6905cc8b902&quot;</ETag>
            <Size>142863</Size>
            <StorageClass>STANDARD</StorageClass>
          </Contents>
          <Contents>
            <Key>sample2.jpg</Key>
            <LastModified>2011-02-26T01:56:20.000Z</LastModified>
            <ETag>&quot;bf1d737a4d46a19f3bced6905cc8b902&quot;</ETag>
            <Size>142863</Size>
            <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>'
      EOS
    end

    subject { session.send(:parse_bucket_listing, response) }

    it { is_expected.to eq([["sample1.jpg", "sample2.jpg"], false]) }
  end

  describe 'bulk_deletion_request_body' do
    let(:expected_response) do
      <<~EOS
        <?xml version="1.0" encoding="UTF-8"?>
        <Delete>
          <Object>
            <Key>chapi</Key>
          </Object>
          <Object>
            <Key>chapo</Key>
          </Object>
        </Delete>
      EOS
    end

    subject { session.send(:bulk_deletion_request_body, ['chapi', 'chapo']) }

    it { is_expected.to eq(expected_response) }
  end
end
