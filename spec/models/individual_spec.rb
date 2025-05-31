describe Individual do
  it { is_expected.to have_db_column(:gender) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:prenom) }
  it { is_expected.to belong_to(:dossier).required }

  describe "prenom normalisation" do
    test_data = {
      ' ADÉLAIDE  ' => 'Adélaide',
      'ANNE GAELLE' => 'Anne Gaelle',
      'ANNE-GAELLE' => 'Anne-Gaelle',
      'franÇois-jean' => "François-Jean",
      'gilbert' => "Gilbert",
      'arthur, gilbert andré , roger' => 'Arthur, Gilbert André , Roger'
    }
    test_data.each do |input, expected|
      it "normalisation of #{input}" do
        individual = create(:individual, prenom: input)
        expect(individual.prenom).to eq(expected)
      end
    end
  end

  describe "nom normalisation" do
    test_data = {
      'lefèvre' => 'LEFÈVRE',
      'de la tourandière' => 'DE LA TOURANDIÈRE',
      'Lalumière-Dufour' => 'LALUMIÈRE-DUFOUR',
      "D'Ornano" => "D'ORNANO",
      ' noël ' => "NOËL"
    }
    test_data.each do |input, expected|
      it "normalisation of #{input}" do
        individual = create(:individual, nom: input)
        expect(individual.nom).to eq(expected)
      end
    end
  end

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

  describe 'validate_mandant_email' do
    let(:user) { create(:user, email: 'mandataire@example.com') }
    let(:dossier) { create(:dossier, :for_tiers_with_notification, user: user) }
    let(:individual) { dossier.individual }

    context 'when validating email' do
      it 'is valid when email is different from the mandataire' do
        individual.email = 'different@example.com'
        expect(individual).to be_valid
      end

      it 'is invalid when email is the same as the mandataire' do
        individual.email = 'mandataire@example.com'
        expect(individual).not_to be_valid
        expect(individual.errors[:email]).to include(
          I18n.t('activerecord.errors.models.individual.attributes.email.must_be_different_from_mandataire')
        )
      end

      it 'is valid when email is not required (notification_method is not email)' do
        dossier_without_notification = create(:dossier, :for_tiers_without_notification, user: user)
        individual_without_notification = dossier_without_notification.individual

        expect(individual_without_notification).to be_valid
        expect(individual_without_notification.email).to be_nil
        expect(individual_without_notification.notification_method).to eq('no_notification')
      end
    end
  end
end
