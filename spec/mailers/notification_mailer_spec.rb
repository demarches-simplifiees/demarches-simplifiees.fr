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
  let(:service) { create(:service) }
  let(:procedure) { create(:simple_procedure, service: service) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }

  describe '.send_notification' do
    let(:email_template) { instance_double('email_template', subject_for_dossier: 'subject', body_for_dossier: 'body') }

    subject(:mail) do
      klass = Class.new(described_class) do
        # We’re testing the (private) method `NotificationMailer#send_notification`.
        #
        # The standard trick to test a private method would be to `send(:send_notification)`, but doesn’t work here,
        # because ActionMailer does some magic to expose public instance methods as class methods.
        # So, we use inheritance instead to make the private method public for testing purposes.
        def send_notification(dossier, template)
          super
        end
      end
      klass.send_notification(dossier, email_template)
    end

    it { expect(mail.to).to include(user.email) }
    it { expect(mail.reply_to).to contain_exactly(dossier.procedure.service.email, CONTACT_EMAIL) }
    it { expect(mail.subject).to eq(email_template.subject_for_dossier) }
    it { expect(mail.body).to include(email_template.body_for_dossier) }
    it { expect(mail.body).to have_link('messagerie') }

    context 'when the procedure service email is invalid' do
      let(:service) { create(:service, email: 'NE_PAS_REPONDRE') }
      it { expect(mail.reply_to).to be_empty }
    end

    context 'when the procedure has no associated service' do
      let(:service) { nil }
      it { expect(mail.reply_to).to be_empty }
    end

    it_behaves_like "create a commentaire not notified"
  end

  describe '.send_dossier_received' do
    subject(:mail) { described_class.send_dossier_received(dossier) }
    let(:email_template) { create(:received_mail) }

    before do
      dossier.procedure.received_mail = email_template
    end

    it do
      expect(mail.subject).to eq(email_template.subject)
      expect(mail.body).to include(email_template.body)
      expect(mail.body).to have_link('messagerie')
    end

    it_behaves_like "create a commentaire not notified"
  end
end
