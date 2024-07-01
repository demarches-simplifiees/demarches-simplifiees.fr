describe Gestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:commentaire_groupe_gestionnaires) }
    it { is_expected.to have_many(:follow_commentaire_groupe_gestionnaires) }
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

  describe "#unread_commentaires?" do
    context "over three different groupe_gestionnaire" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }
      let!(:follow_commentaire_groupe_gestionnaire) { create(:follow_commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, gestionnaire: gestionnaire, sender: administrateur, commentaire_seen_at: Time.zone.now) }

      let(:gestionnaire_unread_commentaire_cause_never_seen) { create(:gestionnaire) }
      let(:administrateur_unread_commentaire_cause_never_seen) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire_unread_commentaire_cause_never_seen) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire_unread_commentaire_cause_never_seen]) }
      let!(:commentaire_groupe_gestionnaire_unread_commentaire_cause_never_seen) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_unread_commentaire_cause_never_seen, sender: administrateur_unread_commentaire_cause_never_seen, created_at: 12.hours.ago) }

      let(:gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire) { create(:gestionnaire) }
      let(:administrateur_unread_commentaire_cause_seen_at_before_last_commentaire) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire]) }
      let!(:commentaire_groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire, sender: administrateur_unread_commentaire_cause_seen_at_before_last_commentaire, created_at: 12.hours.ago) }
      let!(:follow_commentaire_groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire) { create(:follow_commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire, gestionnaire: gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire, sender: administrateur_unread_commentaire_cause_seen_at_before_last_commentaire, commentaire_seen_at: 1.day.ago) }

      it do
        expect(gestionnaire.unread_commentaires?(groupe_gestionnaire)).to eq false
        expect(gestionnaire_unread_commentaire_cause_never_seen.unread_commentaires?(groupe_gestionnaire_unread_commentaire_cause_never_seen)).to eq true
        expect(gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire.unread_commentaires?(groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire)).to eq true
      end
    end

    context "over same groupe_gestionnaire" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:gestionnaire_unread_commentaire_cause_never_seen) { create(:gestionnaire) }
      let(:gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire, gestionnaire_unread_commentaire_cause_never_seen, gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }

      let!(:follow_commentaire_groupe_gestionnaire) { create(:follow_commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, gestionnaire: gestionnaire, sender: administrateur, commentaire_seen_at: Time.zone.now) }
      let!(:follow_commentaire_groupe_gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire) { create(:follow_commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, gestionnaire: gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire, sender: administrateur, commentaire_seen_at: 1.day.ago) }

      it do
        expect(gestionnaire.unread_commentaires?(groupe_gestionnaire)).to eq false
        expect(gestionnaire_unread_commentaire_cause_never_seen.unread_commentaires?(groupe_gestionnaire)).to eq true
        expect(gestionnaire_unread_commentaire_cause_seen_at_before_last_commentaire.unread_commentaires?(groupe_gestionnaire)).to eq true
      end
    end
  end

  describe "#commentaire_seen_at" do
    context "when already seen commentaire" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }
      let!(:follow_commentaire_groupe_gestionnaire) { create(:follow_commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, gestionnaire: gestionnaire, sender: administrateur, commentaire_seen_at: Time.zone.now) }

      it { expect(gestionnaire.commentaire_seen_at(groupe_gestionnaire, administrateur.id, "Administrateur").to_date).to eq Date.current }
    end

    context "when never seen commentaire" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }

      it { expect(gestionnaire.commentaire_seen_at(groupe_gestionnaire, administrateur.id, "Administrateur")).to eq nil }
    end
  end

  describe "#mark_commentaire_as_seen" do
    context "when already seen commentaire" do
      let(:now) { Time.zone.now.beginning_of_minute }
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }
      let!(:follow_commentaire_groupe_gestionnaire) { create(:follow_commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, gestionnaire: gestionnaire, sender: administrateur, commentaire_seen_at: 12.hours.ago) }

      subject do
        travel_to(now) do
          gestionnaire.mark_commentaire_as_seen(groupe_gestionnaire, administrateur.id, "Administrateur")
        end
      end

      it do
        subject
        expect(gestionnaire.commentaire_seen_at(groupe_gestionnaire, administrateur.id, "Administrateur")).to eq now
      end
    end

    context "when never seen commentaire" do
      let(:now) { Time.zone.now.beginning_of_minute }
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs(:default_admin) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }

      subject do
        travel_to(now) do
          gestionnaire.mark_commentaire_as_seen(groupe_gestionnaire, administrateur.id, "Administrateur")
        end
      end

      it do
        subject
        expect(gestionnaire.commentaire_seen_at(groupe_gestionnaire, administrateur.id, "Administrateur")).to eq now
      end
    end
  end
end
