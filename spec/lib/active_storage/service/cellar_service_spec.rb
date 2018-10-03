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
          'response-content-type' => ['image/png']
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
end
