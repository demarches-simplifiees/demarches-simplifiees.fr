describe Gestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to have_and_belong_to_many(:groupe_gestionnaires) }
  end

  describe "#can_be_deleted?" do
    subject { gestionnaire.can_be_deleted? }

    context "when there are several gestionnaires in the groupe gestionnaire" do
      let!(:gestionnaire) { create(:gestionnaire) }
      let!(:autre_gestionnaire) { create(:gestionnaire) }
      let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire, autre_gestionnaire]) }

      it { is_expected.to be true }
    end

    context "when only one gestionnaire in the groupe gestionnaire" do
      let!(:gestionnaire) { create(:gestionnaire) }
      let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }

      it { is_expected.to be false }
    end

    context "when the gestionnaire has no groupe gestionnaire" do
      let!(:gestionnaire) { create(:gestionnaire) }

      it { is_expected.to be true }
    end
  end

  describe "#registration_state" do
    subject { gestionnaire.registration_state }

    context "when active" do
      let!(:gestionnaire) { create(:gestionnaire) }

      before { gestionnaire.user.update(last_sign_in_at: Time.zone.now) }

      it { is_expected.to eq 'Actif' }
    end

    context "when pending" do
      let!(:gestionnaire) { create(:gestionnaire) }

      before { gestionnaire.user.update(reset_password_sent_at: Time.zone.now) }

      it { is_expected.to eq 'En attente' }
    end

    context "when expired" do
      let!(:gestionnaire) { create(:gestionnaire) }

      it { is_expected.to eq 'Expiré' }
    end
  end

  describe "#by_email" do
    context "returns gestionnaire" do
      let!(:gestionnaire) { create(:gestionnaire) }

      it { expect(Gestionnaire.by_email(gestionnaire.email)).to eq gestionnaire }
    end
  end

  describe "#find_all_by_identifier" do
    context "find gestionnaire by email " do
      subject { Gestionnaire.find_all_by_identifier(emails: [gestionnaire.email]) }
      let!(:gestionnaire) { create(:gestionnaire) }

      it { is_expected.to eq [gestionnaire] }
    end

    context "find gestionnaire by id " do
      subject { Gestionnaire.find_all_by_identifier(ids: [gestionnaire.id]) }
      let!(:gestionnaire) { create(:gestionnaire) }

      it { is_expected.to eq [gestionnaire] }
    end
  end
end
