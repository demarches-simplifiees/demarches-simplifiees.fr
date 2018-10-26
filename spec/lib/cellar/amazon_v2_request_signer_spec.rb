require 'net/http'

describe 'AmazonV2RequestSigner' do
  let(:request_signer) do
    # These are actual keys, but they’re safe to put here because
    # - they never had any rights attached, and
    # - the keys were revoked before copying them here

    Cellar::AmazonV2RequestSigner.new(
      'AKIAJFTRSGRH3RXX6D5Q',
      '3/y/3Tf5zkfcrTaLFxyKB/oU2/7ay7/Dz8UdEHC7',
      'rogets'
    )
  end

  before { Timecop.freeze(Time.gm(2016, 10, 2)) }
  after { Timecop.return }

  describe 'signature generation' do
    context 'for presigned URLs' do
      subject do
        request_signer.signature(
          method: 'GET',
          key: 'fichier',
          expires: 5.minutes.from_now.to_i
        )
      end

      it { is_expected.to eq('nzCsB6cip8oofkuOdvvJs6FafkA=') }
    end

    context 'for server-side requests' do
      subject do
        Net::HTTP::Delete.new('https://rogets.cellar.services.clever-cloud.com/fichier')
      end

      before { request_signer.sign(subject, 'fichier') }

      it { expect(subject['date']).to eq(Time.zone.now.httpdate) }
      it { expect(subject['authorization']).to eq('AWS AKIAJFTRSGRH3RXX6D5Q:nkvviwZYb1V9HDrKyJZmY3Z8sSA=') }
    end
  end
end
