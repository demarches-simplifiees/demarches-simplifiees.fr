RSpec.describe InviteMailer, type: :mailer do
  let(:deliver) { mailer.deliver_now }

  describe '.invite_user' do
    let(:mailer) { InviteMailer.invite_user(invite) }

    let(:invite) { create(:invite, user: create(:user)) }
    it 'creates a target_user_link' do
      expect { deliver }
        .to change { TargetedUserLink.where(target_model: invite, user: invite.user).count }
        .from(0).to(1)
    end

    context 'when it fails' do
      it 'creates only one target_user_link' do
         send_mail_values = [:raise, true]
         allow_any_instance_of(InviteMailer).to receive(:send_mail) do
           v = send_mail_values.shift
           v == :raise ? raise("boom") : v
         end

         begin
           mailer.body
         rescue MailDeliveryError
           nil
         end

         mailer.body
         expect(TargetedUserLink.where(target_model: invite, user: invite.user).count).to eq(1)
       end
    end

    context 'without SafeMailer configured' do
      it { expect(mailer[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil) }
    end

    context 'with SafeMailer configured' do
      let(:forced_delivery_method) { :kikoo }
      before { allow(SafeMailer).to receive(:forced_delivery_method).and_return(forced_delivery_method) }
      it { expect(mailer[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(forced_delivery_method.to_s) }
    end
  end

  describe '.invite_guest' do
    let(:mailer) { InviteMailer.invite_guest(invite) }
    let(:invite) { create(:invite, user: nil, email: 'kikoo@lol.fr') }

    it 'creates a target_user_link' do
      expect { deliver }
        .to change { TargetedUserLink.where(target_model: invite, user: nil).count }
        .from(0).to(1)
    end

    context 'when it fails' do
      it 'creates only one target_user_link' do
         send_mail_values = [:raise, true]
         allow_any_instance_of(InviteMailer).to receive(:send_mail) do
           v = send_mail_values.shift
           v == :raise ? raise("boom") : v
         end

         begin
           mailer.body
         rescue MailDeliveryError
           nil
         end

         mailer.body
         expect(TargetedUserLink.where(target_model: invite, user: invite.user).count).to eq(1)
       end
    end
  end
end
