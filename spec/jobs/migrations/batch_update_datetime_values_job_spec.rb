describe Migrations::BatchUpdateDatetimeValuesJob, type: :job do
  before do
    datetime_champ.save(validate: false)
  end

  context "when the value is a valid ISO8601 date" do
    let!(:value) { Time.zone.parse('10/01/2023 13:30').iso8601 }
    let!(:datetime_champ) { build(:champ_datetime, value: value) }

    subject { described_class.perform_now([datetime_champ.id]) }

    it "keeps the existing value" do
      subject
      expect(datetime_champ.reload.value).to eq(value)
    end
  end

  context "when the value is a date convertible to IS8061" do
    let!(:value) { "2023-01-10" }
    let!(:datetime_champ) { build(:champ_datetime, value: value) }

    subject { described_class.perform_now([datetime_champ.id]) }

    it "updates the value to ISO8601" do
      subject
      expect(datetime_champ.reload.value).to eq(Time.zone.parse(value).iso8601)
    end
  end

  context "when the value is a date not convertible to IS8061" do
    let!(:datetime_champ) { build(:champ_datetime, value: "blabla") }

    subject { described_class.perform_now([datetime_champ.id]) }

    it "updates the value to nil" do
      subject
      expect(datetime_champ.reload.value).to be_nil
    end
  end

  context "when the value is a date not convertible to IS8061 and the champ is required" do
    let!(:datetime_champ) { build(:champ_datetime, value: "blabla") }

    subject { described_class.perform_now([datetime_champ.id]) }

    it "keeps the existing value" do
      allow_any_instance_of(Champs::DatetimeChamp).to receive(:required?).and_return(true)

      subject

      expect(datetime_champ.reload.value).to eq("blabla")
    end
  end

  context "when the value is nil" do
    let!(:datetime_champ) { build(:champ_datetime, value: nil) }

    subject { described_class.perform_now([datetime_champ.id]) }

    it "keeps the value to nil" do
      subject
      expect(datetime_champ.reload.value).to be_nil
    end
  end
end
