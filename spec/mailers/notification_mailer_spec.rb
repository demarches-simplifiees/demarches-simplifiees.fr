require "spec_helper"

RSpec.describe NotificationMailer, type: :mailer do
  shared_examples_for "create a commentaire not notified" do
    it do
      expect { subject.deliver_now }.to change { Commentaire.count }.by(1)

      subject.deliver_now
      commentaire = Commentaire.last
      expect(commentaire.body).to include(email_template.subject_for_dossier(dossier), email_template.body_for_dossier(dossier))
      expect(commentaire.dossier).to eq(dossier)
    end
  end

  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, user: user) }

  describe '.send_notification' do
    let(:email_template) { instance_double('email_template', subject_for_dossier: 'subject', body_for_dossier: 'body') }

    subject { described_class.send_notification(dossier, email_template) }

    it { expect(subject.subject).to eq(email_template.subject_for_dossier) }
    it { expect(subject.body).to eq(email_template.body_for_dossier) }
    it_behaves_like "create a commentaire not notified"
  end

  describe '.send_dossier_received' do
    subject { described_class.send_dossier_received(dossier.id) }
    let(:email_template) { create(:received_mail) }

    before do
      dossier.procedure.received_mail = email_template
    end

    it do
      expect(subject.subject).to eq(email_template.subject)
      expect(subject.body).to eq(email_template.body)
    end

    it_behaves_like "create a commentaire not notified"
  end

  describe ".new_answer" do
    subject(:subject) { described_class.new_answer(dossier) }

    it { expect(subject.body).to match('Un nouveau message est disponible dans votre espace demarches-simplifiees.fr.') }
    it { expect(subject.body).to include("Pour le consulter, merci de vous rendre sur #{users_dossier_recapitulatif_url(dossier_id: dossier.id)}") }
    it { expect(subject.subject).to eq("Nouveau message pour votre dossier demarches-simplifiees.fr nº #{dossier.id}") }
  end
end
