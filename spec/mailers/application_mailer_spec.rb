# frozen_string_literal: true

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
        let(:smtp_error) { Net::SMTPSyntaxError.new('400 unexpected recipients: want atleast 1, got 0') }
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

  describe 'dealing with Dolist API error' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure)) }
    subject { DossierMailer.with(dossier:).notify_new_draft.deliver_now }
    context 'not ignored error' do
      before do
        ActionMailer::Base.delivery_method = :dolist_api
        api_error_response = { "ResponseStatus": { "ErrorCode": "Forbidden", "Message": "Blocked non authorized request", "Errors": [] } }
        allow_any_instance_of(Dolist::API).to receive(:send_email).and_return(api_error_response)
      end

      it 'raise classic error to retry' do
        expect { subject }.to raise_error(RuntimeError)
        expect(EmailEvent.pending.count).to eq(1)
      end
    end

    context 'ignored error' do
      before do
        ActionMailer::Base.delivery_method = :dolist_api
        api_error_response = { "ResponseStatus" => { "ErrorCode" => "458", "Message" => "The contact is disabled.", "Errors" => [] } }
        allow_any_instance_of(Dolist::API).to receive(:send_email).and_return(api_error_response)
        allow_any_instance_of(Dolist::API).to receive(:fetch_contact_status).with(dossier.user.email).and_return("7")
      end

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe 'dealing with Dolist API success' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure)) }
    let(:message_id) { "29d9b692-0374-4084-8434-d9cddbced205" }
    before do
      ActionMailer::Base.delivery_method = :dolist_api
      api_success_response = { "Result" => message_id }
      allow_any_instance_of(Dolist::API).to receive(:send_email).and_return(api_success_response)
    end
    subject { DossierMailer.with(dossier:).notify_new_draft.deliver_now }

    it 'forward message ID to observer and EmailEvent.create_from_message!' do
      expect { subject }.to change { EmailEvent.dolist_api.dispatched.where(message_id:).count }.to eq(1)
    end
  end

  describe 'EmailDeliveryObserver is invoked' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user, email: "your@email.com") }

    before { freeze_time }

    it 'creates a new EmailEvent record with the correct information' do
      expect { UserMailer.ask_for_merge(user1, user2.email).deliver_now }.to change { EmailEvent.count }.by(2)
      event = EmailEvent.last
      expect(EmailEvent.first.status).to eq('pending')

      expect(event.to).to eq("your@email.com")
      expect(event.method).to eq("test")
      expect(event.subject).to eq('Fusion de compte')
      expect(event.processed_at).to eq(Time.current)
      expect(event.status).to eq('dispatched')
    end
  end

  context 'EmailDeliveringInterceptor is invoked' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user, email: "your@email.com") }

    context "when there is an error and email are not sent" do
      subject { UserMailer.ask_for_merge(user1, user2.email) }

      before do
        allow_any_instance_of(Mail::Message)
          .to receive(:do_delivery)
          .and_raise(smtp_error)
      end

      context "smtp server busy" do
        let(:smtp_error) { Net::SMTPServerBusy.new('451 4.7.500 Server busy') }

        it "catches the smtp error" do
          expect { subject.deliver_now }.not_to raise_error
          expect(EmailEvent.pending.count).to eq(1)
        end
      end

      context "does not catches other error" do
        let(:smtp_error) { Net::OpenTimeout.new }

        it "re-raise an error and creates an event" do
          expect { subject.deliver_now }.to raise_error(Net::OpenTimeout)
          expect(EmailEvent.pending.count).to eq(1)
        end
      end
    end
  end
end
