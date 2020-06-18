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

    it { expect(Service.new(params).valid?).to be_truthy }

    it 'should forbid invalid phone numbers' do
      service = Service.create(params)
      invalid_phone_numbers = ["1", "Néant", "01 60 50 40 30 20"]

      invalid_phone_numbers.each do |tel|
        service.telephone = tel
        expect(service.valid?).to be_falsey
      end
    end

    it 'should accept no phone numbers' do
      service = Service.create(params)
      service.telephone = nil

      expect(service.valid?).to be_truthy
    end

    it 'should accept valid phone numbers' do
      service = Service.create(params)
      valid_phone_numbers = ["3646", "273115", "0160376983", "01 60 50 40 30 ", "+33160504030"]

      valid_phone_numbers.each do |tel|
        service.telephone = tel
        expect(service.valid?).to be_truthy
      end
    end

    context 'when a first service exists' do
      before { Service.create(params) }

      context 'checks uniqueness of administrateur, name couple' do
        it { expect(Service.create(params).valid?).to be_falsey }
      end
    end

    context 'of type_organisme' do
      it 'should be set' do
        expect(Service.new(params.except(:type_organisme)).valid?).to be_falsey
      end
    end

    context 'of nom' do
      it 'should be set' do
        expect(Service.new(params.except(:nom)).valid?).to be_falsey
      end
    end

    context 'of administrateur' do
      it 'should be set' do
        expect(Service.new(params.except(:administrateur_id)).valid?).to be_falsey
      end
    end

    context 'of type_organisme' do
      it 'should belong to the enum' do
        expect { Service.new(params.merge(type_organisme: 'choucroute')) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'suggested_path' do
    subject { service.suggested_path }
    context 'service name with one word' do
      let(:service) { create :service, nom: 'SEFI' }
      it { is_expected.to eq 'sefi' }
    end

    context 'service name with multiple words & prepositions' do
      let(:service) { create :service, nom: "Direction de la Jeunesse et des sports et de l'économie" }
      it { is_expected.to eq 'djse' }
    end

    context 'service name with dash' do
      let(:service) { create :service, nom: 'SEFI - Revenu Exceptionnel de Solidarité' }
      it { is_expected.to eq 'sefi' }
    end

    context 'service name with colon' do
      let(:service) { create :service, nom: 'SEFI: Revenu Exceptionnel de Solidarité' }
      it { is_expected.to eq 'sefi' }
    end
  end
end
