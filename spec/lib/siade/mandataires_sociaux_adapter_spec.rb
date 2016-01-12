require 'spec_helper'

describe SIADE::MandatairesSociauxAdapter do
  subject { described_class.new('418166096').to_params }

  before do
    stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/418166096?token=#{SIADETOKEN}")
      .to_return(body: File.read('spec/support/files/entreprise.json', status: 200))
  end

  it '#to_params class est une Hash ?' do
    expect(subject).to be_an_instance_of(Hash)
  end

  describe 'Mandataires Sociaux' do

    it { expect(subject.size).to eq(8) }

    describe 'Attributs' do

      it 'Un mandataire social possède bien un nom' do
        expect(subject[0][:nom]).to eq('HISQUIN')
      end
      it 'Un mandataire social possède bien un prenom' do
        expect(subject[0][:prenom]).to eq('FRANCOIS')
      end

      it 'Un mandataire social possède bien une fonction' do
        expect(subject[0][:fonction]).to eq('PRESIDENT DU DIRECTOIRE')
      end

      it 'Un mandataire social possède bien une date de naissance' do
        expect(subject[0][:date_naissance]).to eq('1965-01-27')
      end

      it 'Un mandataire social possède bien une date de naissance au format timestamp' do
        expect(subject[0][:date_naissance_timestamp]).to eq(-155523600)
      end


    end
  end
end
