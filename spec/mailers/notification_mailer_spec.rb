require "spec_helper"

RSpec.describe NotificationMailer, type: :mailer do
  describe '.send_notification' do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user) }
    let(:email) { instance_double('email', object_for_dossier: 'object', body_for_dossier: 'body') }
    let (:notifications_count_before) { Notification.count }
    subject { described_class.send_notification(dossier, email) }

    it { expect(subject.subject).to eq(email.object_for_dossier) }
    it { expect(subject.body).to eq(email.body_for_dossier) }

    it "creates a commentaire, which is not notified" do
      described_class.send_notification(dossier, email).deliver_now

      commentaire = Commentaire.last
      notifications_count_after = Notification.count

      expect(commentaire.dossier).to eq(dossier)
      expect(commentaire.email).to eq("contact@tps.apientreprise.fr")
      expect(commentaire.body).to eq("[object]<br><br>body")
      expect(notifications_count_before).to eq(notifications_count_after)
    end
  end

  describe ".new_answer" do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user) }

    subject(:subject) { described_class.new_answer(dossier) }

    it { expect(subject.body).to match('Un nouveau message est disponible dans votre espace TPS.') }
    it { expect(subject.body).to include("Pour le consulter, merci de vous rendre sur #{users_dossier_recapitulatif_url(dossier_id: dossier.id)}") }
    it { expect(subject.subject).to eq("Nouveau message pour votre dossier TPS nº #{dossier.id}") }
  end
end
