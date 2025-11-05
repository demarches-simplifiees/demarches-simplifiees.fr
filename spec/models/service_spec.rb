# frozen_string_literal: true

describe Service, type: :model do
  describe 'validation' do
    let(:administrateur) { administrateurs(:default_admin) }
    let(:params) do
      {
        nom: 'service des jardins',
        organisme: 'mairie des iles',
        type_organisme: Service.type_organismes.fetch(:association),
        email: 'super@email.com',
        telephone: '012345678',
        horaires: 'du lundi au vendredi',
        adresse: '12 rue des schtroumpfs',
        administrateur_id: administrateur.id,
        siret: "35600011719156",
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

    describe "email and contact_link" do
      it 'should be valid if only email is present' do
        subject.email = 'super@email.com'
        subject.contact_link = nil
        expect(subject).to be_valid
      end

      it 'should be valid if only contact_link is present' do
        subject.email = nil
        subject.contact_link = 'www.test.fr/faq'
        expect(subject).to be_valid
      end

      it 'should be valid if email and contact_link are present' do
        subject.email = 'super@email.com'
        subject.contact_link = 'www.test.fr/faq'
        expect(subject).to be_valid
      end

      it 'should be invalid if none are present' do
        subject.email = nil
        subject.contact_link = nil
        expect(subject).not_to be_valid
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

  describe 'validation on update' do
    subject { create(:service) }

    it 'should not allow to have a test siret' do
      subject.siret = Service::SIRET_TEST
      expect(subject).not_to be_valid
    end
  end

  describe "etablissement adresse & geo coordinates" do
    subject { create(:service, etablissement_lat: latitude, etablissement_lng: longitude, etablissement_infos: etablissement_infos) }

    context "when the service has no geo coordinates" do
      let(:latitude) { nil }
      let(:longitude) { nil }
      let(:etablissement_infos) { {} }
      it "should return nil" do
        expect(subject.etablissement_lat).to be_nil
        expect(subject.etablissement_lng).to be_nil
        expect(subject.etablissement_adresse).to be_nil
      end
    end

    context "when the service has geo coordinates" do
      let(:latitude) { 43.5 }
      let(:longitude) { 4.7 }
      let(:adresse) { "174 Chemin du Beurre\n13200\nARLES\nFRANCE" }
      let(:etablissement_infos) { { adresse: adresse } }

      it "should return nil" do
        expect(subject.etablissement_lat).to eq(43.5)
        expect(subject.etablissement_lng).to eq(4.7)
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
