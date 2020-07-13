RSpec.describe ApplicationMailer, type: :mailer do
  describe 'dealing with invalid emails' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }
    subject { DossierMailer.notify_new_draft(dossier) }

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
end
