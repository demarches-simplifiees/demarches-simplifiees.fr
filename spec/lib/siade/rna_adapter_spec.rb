require 'spec_helper'

describe SIADE::RNAAdapter do
  let(:siret) { '50480511000013' }
  let(:body) { File.read('spec/support/files/rna.json') }
  let(:status) { 200 }

  subject { described_class.new(siret).to_params }

  before do
    stub_request(:get, /https:\/\/apientreprise.fr\/api\/v1\/associations\/.*token=/)
        .to_return(body: body, status: status)
  end

  context 'when siret is not valid' do
    let(:siret) { '234567' }
    let(:body) { '' }
    let(:status) { '404' }

    it { is_expected.to eq(nil) }
  end

  it { expect(subject).to be_an_instance_of(Hash) }

  describe 'Attributs Associations' do
    it { expect(subject[:association_id]).to eq('W595001988') }

    it { expect(subject[:titre]).to eq('UN SUR QUATRE') }

    it { expect(subject[:objet]).to eq("valoriser, transmettre et partager auprès des publics les plus larges possibles, les bienfaits de l'immigration, la richesse de la diversité et la curiosité de l'autre autrement") }

    it { expect(subject[:date_creation]).to eq('2014-01-23') }

    it { expect(subject[:date_declaration]).to eq('2014-01-24') }

    it { expect(subject[:date_publication]).to eq('2014-02-08') }
  end
end
