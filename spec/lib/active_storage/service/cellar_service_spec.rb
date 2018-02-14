require 'active_storage/service/cellar_service'
require 'cgi'
require 'net/http'
require 'uri'

describe 'CellarService' do
  let(:cellar_service) do
    # These are actual keys, but they’re safe to put here because
    # - they never had any rights attached, and
    # - the keys were revoked before copying them here

    ActiveStorage::Service::CellarService.new(
      access_key_id: 'AKIAJFTRSGRH3RXX6D5Q',
      secret_access_key: '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',
      bucket: 'rogets'
    )
  end

  before { Timecop.freeze(Time.gm(2016, 10, 2)) }
  after { Timecop.return }

  describe 'signature generation' do
    context 'for presigned URLs' do
      subject do
        cellar_service.send(
          :signature,
          {
            method: 'GET',
            key: 'fichier',
            expires: 5.minutes.from_now.to_i
          }
        )
      end

      it { is_expected.to eq('nzCsB6cip8oofkuOdvvJs6FafkA=') }
    end

    context 'for server-side requests' do
      subject do
        Net::HTTP::Delete.new('https://rogets.cellar.services.clever-cloud.com/fichier')
      end

      before { cellar_service.send(:sign, subject, 'fichier') }

      it { expect(subject['date']).to eq(Time.now.httpdate) }
      it { expect(subject['authorization']).to eq('AWS AKIAJFTRSGRH3RXX6D5Q:nkvviwZYb1V9HDrKyJZmY3Z8sSA=') }
    end
  end

  describe 'presigned url for download' do
    subject do
      URI.parse(
        cellar_service.url(
          'fichier',
          expires_in: 5.minutes,
          filename: ActiveStorage::Filename.new("toto.png"),
          disposition: 'attachment',
          content_type: 'image/png'
        )
      )
    end

    it do
      is_expected.to have_attributes(
        scheme: 'https',
        host: 'rogets.cellar.services.clever-cloud.com',
        path: '/fichier'
      )
    end

    it do
      expect(CGI::parse(subject.query)).to eq(
        {
          'AWSAccessKeyId' => ['AKIAJFTRSGRH3RXX6D5Q'],
          'Expires' => ['1475366700'],
          'Signature' => ['nzCsB6cip8oofkuOdvvJs6FafkA='],
          'response-content-disposition' => ["attachment; filename=\"toto.png\"; filename*=UTF-8''toto.png"],
          'response-content-type' => ['image/png'],
        }
      )
    end
  end

  describe 'presigned url for direct upload' do
    subject do
      URI.parse(
        cellar_service.url_for_direct_upload(
          'fichier',
          expires_in: 5.minutes,
          content_type: 'image/png',
          content_length: 2713,
          checksum: 'DEADBEEF'
        )
      )
    end

    it do
      is_expected.to have_attributes(
        scheme: 'https',
        host: 'rogets.cellar.services.clever-cloud.com',
        path: '/fichier'
      )
    end

    it do
      expect(CGI::parse(subject.query)).to eq(
        {
          'AWSAccessKeyId' => ['AKIAJFTRSGRH3RXX6D5Q'],
          'Expires' => ['1475366700'],
          'Signature' => ['VwsX5nxGfTC3dxXjS6wSeU64r5o=']
        }
      )
    end
  end

  describe 'parse_bucket_listing' do
    let(:response) do
      '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
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
    end

    subject { cellar_service.send(:parse_bucket_listing, response) }

    it { is_expected.to eq(["sample1.jpg", "sample2.jpg"]) }
  end

  describe 'bulk_deletion_request_body' do
    let(:expected_response) do
      '<?xml version="1.0" encoding="UTF-8"?>
<Delete>
  <Quiet>true</Quiet>
  <Object>
    <Key>chapi</Key>
  </Object>
  <Object>
    <Key>chapo</Key>
  </Object>
</Delete>
'
    end

    subject { cellar_service.send(:bulk_deletion_request_body, ['chapi', 'chapo']) }

    it { is_expected.to eq(expected_response) }
  end
end
