RSpec.describe ApplicationMailer, type: :mailer do
  describe 'dealing with invalid emails' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure)) }
    subject { DossierMailer.with(dossier:).notify_new_draft }

    describe 'invalid emails are not sent' do
      before do
        allow_any_instance_of(DossierMailer)
          .to receive(:notify_new_draft)
          .and_raise(smtp_error)
      end

      context 'when the server handles invalid emails with Net::SMTPSyntaxError' do
        let(:smtp_error) { Net::SMTPSyntaxError.new }
        it { expect(subject.message).to be_an_instance_of(ActionMailer::Base::NullMail) }
      end

      context 'when the server handles invalid emails with Net::SMTPServerBusy' do
        let(:smtp_error) { Net::SMTPServerBusy.new('400 unexpected recipients: want atleast 1, got 0') }
        it { expect(subject.message).to be_an_instance_of(ActionMailer::Base::NullMail) }
      end
    end

    describe 'valid emails are sent' do
      it { expect(subject.message).not_to be_an_instance_of(ActionMailer::Base::NullMail) }
    end
  end

  describe 'EmailDeliveryObserver is invoked' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user, email: "your@email.com") }

    it 'creates a new EmailEvent record with the correct information' do
      expect { UserMailer.ask_for_merge(user1, user2.email).deliver_now }.to change { EmailEvent.count }.by(1)
      event = EmailEvent.last

      expect(event.to).to eq("your@email.com")
      expect(event.method).to eq("test")
      expect(event.subject).to eq('Fusion de compte')
      expect(event.processed_at).to be_within(1.second).of(Time.zone.now)
      expect(event.status).to eq('dispatched')
    end

    context "when there is an error and email are not sent" do
      subject { UserMailer.ask_for_merge(user1, user2.email) }

      before do
        allow_any_instance_of(Mail::Message)
          .to receive(:deliver)
          .and_raise(smtp_error)
      end

      context "smtp server busy" do
        let(:smtp_error) { Net::SMTPServerBusy.new }

        it "re-raise an error and creates an event" do
          expect { subject.deliver_now }.to change { EmailEvent.count }.by(1).and raise_error(MailDeliveryError)
          expect(EmailEvent.last.status).to eq('dispatch_error')
        end
      end

      context "generic unknown error" do
        let(:smtp_error) { Net::OpenTimeout.new }

        it "re-raise an error and creates an event" do
          expect { subject.deliver_now }.to change { EmailEvent.count }.by(1).and raise_error(MailDeliveryError)
          expect(EmailEvent.last.status).to eq('dispatch_error')
        end
      end
    end
  end
end
