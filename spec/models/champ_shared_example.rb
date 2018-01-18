shared_examples 'champ_spec' do
  describe 'mandatory_and_blank?' do
    let(:type_de_champ) { TypeDeChamp.new(mandatory: mandatory) }
    let(:champ) { Champ.new(type_de_champ: type_de_champ, value: value) }
    let(:value) { '' }
    let(:mandatory) { true }

    context 'when mandatory and blank' do
      it { expect(champ.mandatory_and_blank?).to be(true) }
    end

    context 'when not blank' do
      let(:value) { 'yop' }
      it { expect(champ.mandatory_and_blank?).to be(false) }
    end

    context 'when not mandatory' do
      let(:mandatory) { false }
      it { expect(champ.mandatory_and_blank?).to be(false) }
    end

    context 'when not mandatory or blank' do
      let(:value) { 'u' }
      let(:mandatory) { false }
      it { expect(champ.mandatory_and_blank?).to be(false) }
    end
  end

  describe '.departement', vcr: { cassette_name: 'call_geo_api_departements' } do
    subject { Champ.departements }

    it { expect(subject).to include '99 - Étranger' }
  end

  context "when type_champ=date" do
    let(:type_de_champ) { create(:type_de_champ_public, type_champ: "date") }
    let(:champ) { create(:champ, type_de_champ: type_de_champ) }

    it "should convert %d/%m/%Y format to ISO" do
      champ.value = "31/12/2017"
      champ.save
      champ.reload
      expect(champ.value).to eq("2017-12-31")
    end

    it "should convert to nil if date parse failed" do
      champ.value = "bla"
      champ.save
      champ.reload
      expect(champ.value).to be(nil)
    end

    it "should convert empty string to nil" do
      champ.value = ""
      champ.save
      champ.reload
      expect(champ.value).to be(nil)
    end
  end
end
