# frozen_string_literal: true

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
        administrateur: administrateur,
        siret: "35600011719156"
      }
    end

    subject { Service.new(params) }

    it { expect(Service.new(params)).to be_valid }

    describe 'contact information validation' do
      it 'requires at least one contact method' do
        subject.email = nil
        subject.link = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to include("Veuillez renseigner au moins un des deux champs de contact")
      end

      it 'accepts email only' do
        subject.email = 'contact@example.com'
        subject.link = nil
        expect(subject).to be_valid
      end

      it 'accepts link only' do
        subject.email = nil
        subject.link = 'https://example.com/contact'
        expect(subject).to be_valid
      end

      it 'accepts both email and link' do
        subject.email = 'contact@example.com'
        subject.link = 'https://example.com/contact'
        expect(subject).to be_valid
      end

      it 'validates link format' do
        subject.email = nil
        subject.link = 'not-a-url'
        expect(subject).not_to be_valid
        expect(subject.errors[:link]).to be_present
      end
    end

    describe "email or contact link" do
      it 'should accept a valid URL' do
        subject.email = nil
        subject.link = 'https://www.service-public.fr/contact'
        expect(subject).to be_valid
      end

      it 'should accept a valid email' do
        subject.link = nil
        subject.email = 'contact@service-public.fr'
        expect(subject).to be_valid
      end

      it 'should not accept an invalid email' do
        subject.link = nil
        subject.email = 'contact@domain'
        expect(subject).not_to be_valid
      end

      it 'should not accept an invalid URL in link field' do
        subject.email = nil
        subject.link = 'not-an-url'
        expect(subject).not_to be_valid
      end

      it 'should not accept empty contact fields' do
        subject.email = ''
        subject.link = ''
        expect(subject).not_to be_valid
        subject.email = nil
        subject.link = nil
        expect(subject).not_to be_valid
      end
    end

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

    describe "siret" do
      it 'should not be invalid' do
        subject.siret = "012345678901234"
        expect(subject).not_to be_valid
      end

      it 'should be required' do
        subject.siret = nil
        expect(subject).not_to be_valid
      end
    end

    describe 'when a first service exists' do
      before do
        create(:service, :with_both_contacts, nom: 'My Service', administrateur: administrateur)
      end

      it 'checks uniqueness of administrateur, name couple' do
        new_service = build(:service, :with_both_contacts, nom: 'My Service', administrateur: administrateur)
        expect(new_service).not_to be_valid
        expect(new_service.errors[:nom]).to include('existe déjà')

        # Should be valid with same name but different administrateur
        other_admin = create(:administrateur)
        new_service.administrateur = other_admin
        expect(new_service).to be_valid
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
        expect(Service.new(params.except(:administrateur))).not_to be_valid
      end
    end

    context 'of type_organisme' do
      it 'should belong to the enum' do
        expect { Service.new(params.merge(type_organisme: 'choucroute')) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'validation on update' do
    let(:service) { create(:service, :with_both_contacts) }

    it 'should not allow to have a test siret' do
      service.siret = Service::SIRET_TEST
      service.validate
      expect(service).not_to be_valid
      expect(service.errors[:siret]).to include("n'est pas valide")
    end
  end

  describe "etablissement adresse & geo coordinates" do
    subject { build(:service, etablissement_lat: latitude, etablissement_lng: longitude, etablissement_infos: etablissement_infos) }

    context "when the service has no geo coordinates" do
      let(:latitude) { nil }
      let(:longitude) { nil }
      let(:etablissement_infos) { {} }

      it "should return nil values" do
        expect(subject.etablissement_latlng).to eq([nil, nil])
        expect(subject.etablissement_adresse).to be_nil
      end
    end

    context "when the service has geo coordinates" do
      let(:latitude) { 43.5 }
      let(:longitude) { 4.7 }
      let(:adresse) { "174 Chemin du Beurre\n13200\nARLES\nFRANCE" }
      let(:etablissement_infos) { { "adresse" => adresse } }

      it "should return coordinates" do
        expect(subject.etablissement_latlng).to eq([43.5, 4.7])
      end

      it "should return etablissement adresse" do
        expect(subject.etablissement_adresse).to eq(adresse)
      end
    end
  end

  describe 'etablissement_latlng' do
    it 'without coordinates' do
      service = build(:service, etablissement_lat: nil, etablissement_lng: nil)
      expect(service.etablissement_latlng).to eq([nil, nil])
    end

    it 'with coordinates' do
      service = build(:service)
      expect(service.etablissement_latlng).to eq([48.87, 2.34])
    end
  end
end
