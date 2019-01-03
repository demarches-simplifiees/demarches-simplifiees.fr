describe Service, type: :model do
  describe 'validation' do
    let(:administrateur) { create(:administrateur) }
    let(:params) do
      {
        nom: 'service des jardins',
        organisme: 'mairie des iles',
        type_organisme: Service.type_organismes.fetch(:commune),
        email: 'super@email.com',
        telephone: '1212202',
        horaires: 'du lundi au vendredi',
        adresse: '12 rue des schtroumpfs',
        administrateur_id: administrateur.id
      }
    end

    it { expect(Service.new(params).valid?).to be_truthy }

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
end
