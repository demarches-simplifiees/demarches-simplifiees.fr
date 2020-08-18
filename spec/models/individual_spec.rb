describe Individual do
  it { is_expected.to have_db_column(:gender) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:prenom) }
  it { is_expected.to belong_to(:dossier).required }

  describe "#save" do
    let(:individual) { build(:individual) }

    subject { individual.save }

    context "with birthdate" do
      before do
        individual.birthdate = birthdate_from_user
        subject
      end

      context "and the format is dd/mm/yyy " do
        let(:birthdate_from_user) { "12/11/1980" }

        it { expect(individual.birthdate).to eq(Date.new(1980, 11, 12)) }
      end

      context "and the format is ISO" do
        let(:birthdate_from_user) { "1980-11-12" }

        it { expect(individual.birthdate).to eq(Date.new(1980, 11, 12)) }
      end

      context "and the format is WTF" do
        let(:birthdate_from_user) { "1980 1 12" }

        it { expect(individual.birthdate).to be_nil }
      end
    end
  end
end
