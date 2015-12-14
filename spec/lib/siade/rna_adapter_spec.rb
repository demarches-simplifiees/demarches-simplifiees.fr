require 'spec_helper'

describe SIADE::RNAAdapter do
  let(:siret) { '50480511000013' }
  let(:body) { File.read('spec/support/files/rna.json') }
  let(:status) { 200 }
  subject { described_class.new(siret).to_params }

  before do
    stub_request(:get, /https:\/\/api-dev.apientreprise.fr\/api\/v1\/associations\/.*token=/)
        .to_return(body: body, status: status)
  end

  context 'when siret is not valid' do
    let(:siret) { '234567' }
    let(:body) { '' }
    let(:status) { '404' }
    it { is_expected.to eq(nil) }
  end

  it '#to_params class est une Hash ?' do
    expect(subject).to be_an_instance_of(Hash)
  end

  context 'Attributs Associations' do
    it 'L\'associations contient bien un id' do
      expect(subject[:association_id]).to eq('W595001988')
    end

    it 'L\'associations contient bien un titre' do
      expect(subject[:titre]).to eq('UN SUR QUATRE')
    end

    it 'L\'associations contient bien un objet' do
      expect(subject[:objet]).to eq("valoriser, transmettre et partager auprès des publics les plus larges possibles, les bienfaits de l'immigration, la richesse de la diversité et la curiosité de l'autre autrement")
    end

    it 'L\'associations contient bien une date de creation' do
      expect(subject[:date_creation]).to eq('2014-01-23')
    end

    it 'L\'associations contient bien une date de de declaration' do
      expect(subject[:date_declaration]).to eq('2014-01-24')
    end

    it 'L\'associations contient bien une date de publication' do
      expect(subject[:date_publication]).to eq('2014-02-08')
    end
  end
end
