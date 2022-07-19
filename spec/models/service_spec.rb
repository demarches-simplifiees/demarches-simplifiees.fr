describe Service, type: :model do
  describe 'validation' do
    let(:administrateur) { create(:administrateur) }
    let(:params) do
      {
        nom: 'service des jardins',
        organisme: 'mairie des iles',
        type_organisme: Service.type_organismes.fetch(:association),
        email: 'super@email.com',
        telephone: '012345678',
        horaires: 'du lundi au vendredi',
        adresse: '12 rue des schtroumpfs',
        administrateur_id: administrateur.id
      }
    end

    subject { Service.new(params) }

    it { expect(Service.new(params)).to be_valid }

    it 'should forbid invalid phone numbers' do
      invalid_phone_numbers = ["1", "Néant", "01 60 50 40 30 20"]

      invalid_phone_numbers.each do |tel|
        subject.telephone = tel
        expect(subject).not_to be_valid
      end
    end

    it 'should accept no phone numbers' do
      subject.telephone = nil
      expect(subject).to be_valid
    end

    it 'should accept valid phone numbers' do
      valid_phone_numbers = ["3646", "273115", "0160376983", "01 60 50 40 30 ", "+33160504030"]

      valid_phone_numbers.each do |tel|
        subject.telephone = tel
        expect(subject).to be_valid
      end
    end

    context 'when a first service exists' do
      before { Service.create(params) }

      context 'checks uniqueness of administrateur, name couple' do
        it { expect(Service.create(params)).not_to be_valid }
      end
    end

    context 'of type_organisme' do
      it 'should be set' do
        expect(Service.new(params.except(:type_organisme))).not_to be_valid
      end
    end

    context 'of nom' do
      it 'should be set' do
        expect(Service.new(params.except(:nom))).not_to be_valid
      end
    end

    context 'of administrateur' do
      it 'should be set' do
        expect(Service.new(params.except(:administrateur_id))).not_to be_valid
      end
    end

    context 'of type_organisme' do
      it 'should belong to the enum' do
        expect { Service.new(params.merge(type_organisme: 'choucroute')) }.to raise_error(ArgumentError)
      end
    end
  end
end
