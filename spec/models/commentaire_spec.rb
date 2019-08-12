require 'spec_helper'

describe Commentaire do
  it { is_expected.to have_db_column(:email) }
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:created_at) }
  it { is_expected.to have_db_column(:updated_at) }
  it { is_expected.to belong_to(:dossier) }

  describe 'messagerie_available validation' do
    subject { commentaire.valid?(:create) }

    context 'with a commentaire created by the DS system' do
      let(:commentaire) { build :commentaire, email: CONTACT_EMAIL }

      it { is_expected.to be_truthy }
    end

    context 'on an archived dossier' do
      let(:dossier) { create :dossier, :archived }
      let(:commentaire) { build :commentaire, dossier: dossier }

      it { is_expected.to be_falsey }
    end

    context 'on a dossier en_construction' do
      let(:dossier) { create :dossier, :en_construction }
      let(:commentaire) { build :commentaire, dossier: dossier }

      it { is_expected.to be_truthy }
    end
  end

  describe "#sent_by_system?" do
    subject { commentaire.sent_by_system? }

    let(:commentaire) { build :commentaire, email: email }

    context 'with a commentaire created by the DS system' do
      let(:email) { CONTACT_EMAIL }

      it { is_expected.to be_truthy }
    end
  end

  describe "#redacted_email" do
    subject { commentaire.redacted_email }

    context 'with a commentaire created by a instructeur' do
      let(:commentaire) { build :commentaire, instructeur: instructeur }
      let(:instructeur) { build :instructeur, email: 'some_user@exemple.fr' }

      it { is_expected.to eq 'some_user' }
    end

    context 'with a commentaire created by a user' do
      let(:commentaire) { build :commentaire, user: user }
      let(:user) { build :user, email: 'some_user@exemple.fr' }

      it { is_expected.to eq 'some_user@exemple.fr' }
    end
  end

  describe "#notify" do
    let(:procedure) { create(:procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:assign_to) { create(:assign_to, instructeur: instructeur, procedure: procedure) }
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure, user: user) }
    let(:commentaire) { Commentaire.new(dossier: dossier, body: "Mon commentaire") }

    context "with a commentaire created by a instructeur" do
      it "calls notify_user" do
        expect(commentaire).to receive(:notify_user)

        commentaire.email = instructeur.email
        commentaire.save
      end
    end

    context "with a commentaire automatically created (notification)" do
      it "does not call notify_user or notify_instructeurs" do
        expect(commentaire).not_to receive(:notify_user)
        expect(commentaire).not_to receive(:notify_instructeurs)

        commentaire.email = CONTACT_EMAIL
        commentaire.save
      end
    end
  end
end
