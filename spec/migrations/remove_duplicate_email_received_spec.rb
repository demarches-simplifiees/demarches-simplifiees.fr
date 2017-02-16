load 'spec/spec_helper.rb'
load 'db/migrate/20170215102943_remove_duplicate_email_received.rb'

describe RemoveDuplicateEmailReceived do
  context 'with one procedure and one associated mail_received' do
    let!(:procedure) { create(:procedure) }

    it 'keeps the procedure mails' do
      RemoveDuplicateEmailReceived.new.change
      expect(MailReceived.count).to eq(1)
    end

    context 'and another mail_received' do
      before :each do
        MailReceived.create!(procedure: procedure)
      end

      it 'destroys the unecessary maiL_received' do
        RemoveDuplicateEmailReceived.new.change
        expect(MailReceived.count).to eq(1)
        expect(procedure.mail_received).not_to be_nil
      end
    end
  end
end
