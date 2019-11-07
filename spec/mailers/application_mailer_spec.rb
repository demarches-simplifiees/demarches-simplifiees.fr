RSpec.describe ApplicationMailer, type: :mailer do
  describe 'dealing with invalid emails' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }
    subject { DossierMailer.notify_new_draft(dossier) }

    describe 'invalid emails are not sent' do
      before do
        allow_any_instance_of(DossierMailer)
          .to receive(:notify_new_draft)
          .and_raise(Net::SMTPSyntaxError)
      end

      it { expect(subject.message).to be_an_instance_of(ActionMailer::Base::NullMail) }
    end

    describe 'valid emails are sent' do
      it { expect(subject.message).not_to be_an_instance_of(ActionMailer::Base::NullMail) }
    end
  end
end
