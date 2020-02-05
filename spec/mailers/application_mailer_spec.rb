RSpec.describe ApplicationMailer, type: :mailer do
  describe 'dealing with invalid emails' do
    let(:dossier) { create(:dossier, procedure: build(:simple_procedure)) }
    subject { DossierMailer.notify_new_draft(dossier) }

    describe 'valid emails are sent' do
      it { expect(subject.message).not_to be_an_instance_of(ActionMailer::Base::NullMail) }
    end
  end
end
