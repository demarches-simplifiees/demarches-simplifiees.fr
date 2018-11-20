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

    subject(:mail) do
      klass = Class.new(described_class) do
        # We’re testing the (private) method `NotificationMailer#send_notification`.
        #
        # The standard trick to test a private method would be to `send(:send_notification)`, but doesn’t work here,
        # because ActionMailer does some magic to expose public instace methods as class methods.
        # So, we use inheritance instead to make the private method public for testing purposes.
        def send_notification(dossier, template)
          super
        end
      end
      klass.send_notification(dossier, email_template)
    end

    it { expect(mail.subject).to eq(email_template.subject_for_dossier) }
    it { expect(mail.body).to include(email_template.body_for_dossier) }
    it { expect(mail.body).to have_selector('.footer') }

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
      expect(mail.body).to have_selector('.footer')
    end

    it_behaves_like "create a commentaire not notified"
  end
end
