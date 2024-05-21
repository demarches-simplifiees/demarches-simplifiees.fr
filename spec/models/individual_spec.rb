describe Individual do
  it { is_expected.to have_db_column(:gender) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:prenom) }
  it { is_expected.to belong_to(:dossier).required }

  describe "#save" do
    let(:individual) { build(:individual) }

    subject do
      individual.save
      individual
    end

    context "with birthdate" do
      before do
        individual.birthdate = birthdate_from_user
      end

      context "and the format is dd/mm/yyy " do
        let(:birthdate_from_user) { "12/11/1980" }

        it { expect(subject.birthdate).to eq(Date.new(1980, 11, 12)) }
      end

      context "and the format is ISO" do
        let(:birthdate_from_user) { "1980-11-12" }

        it { expect(subject.birthdate).to eq(Date.new(1980, 11, 12)) }
      end

      context "and the format is WTF" do
        let(:birthdate_from_user) { "1980 1 12" }

        it { expect(subject.birthdate).to be_nil }
      end
    end

    it "schedule index search terms" do
      subject.dossier.debounce_index_search_terms_flag.remove
      assert_enqueued_jobs(1, only: DossierIndexSearchTermsJob) do
        individual.update(nom: "new name")
      end
    end
  end

  context 'when an individual has an invalid notification_method' do
    let(:invalid_individual) { build(:individual, notification_method: 'invalid_method') }

    it 'raises an ArgumentError' do
      expect {
        invalid_individual.valid?
      }.to raise_error(ArgumentError, "'invalid_method' is not a valid notification_method")
    end
  end
end
