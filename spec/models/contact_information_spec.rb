# frozen_string_literal: true

describe ContactInformation, type: :model do
  describe 'validation' do
    let(:gi) { create(:groupe_instructeur) }
    let(:params) do
      {
        nom: 'service des jardins',
        email: 'super@email.com',
        telephone: '012345678',
        horaires: 'du lundi au vendredi',
        adresse: '12 rue des schtroumpfs',
        groupe_instructeur_id: gi.id
      }
    end

    subject { ContactInformation.new(params) }

    it { expect(subject).to be_valid }

    it 'should forbid invalid phone numbers' do
      invalid_phone_numbers = ["1", "Néant", "01 60 50 40 30 20"]

      invalid_phone_numbers.each do |tel|
        subject.telephone = tel
        expect(subject).not_to be_valid
      end
    end

    it 'should not accept no phone numbers' do
      subject.telephone = nil
      expect(subject).not_to be_valid
    end

    it 'should accept valid phone numbers' do
      valid_phone_numbers = ["3646", "273115", "0160376983", "01 60 50 40 30 ", "+33160504030"]

      valid_phone_numbers.each do |tel|
        subject.telephone = tel
        expect(subject).to be_valid
      end
    end

    context 'when a contact information already exists' do
      before { ContactInformation.create(params) }

      context 'checks uniqueness of administrateur, name couple' do
        it { expect(ContactInformation.create(params)).not_to be_valid }
      end
    end

    context 'of nom' do
      it 'should be set' do
        expect(ContactInformation.new(params.except(:nom))).not_to be_valid
      end
    end

    context 'of groupe instructeur' do
      it 'should be set' do
        expect(ContactInformation.new(params.except(:groupe_instructeur_id))).not_to be_valid
      end
    end
  end
end
