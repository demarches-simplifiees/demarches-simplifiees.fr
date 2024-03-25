RSpec.describe DeviseUserMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:token) { SecureRandom.hex }
  describe '.confirmation_instructions' do
    subject { described_class.confirmation_instructions(user, token, opts = {}) }

    context 'without SafeMailer configured' do
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil) }
    end

    context 'with SafeMailer configured' do
      let(:forced_delivery_method) { :kikoo }
      before { allow(SafeMailer).to receive(:forced_delivery_method).and_return(forced_delivery_method) }
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(forced_delivery_method.to_s) }
    end

    context 'when perform_later is called' do
      it 'enqueues email in default queue for high priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(Rails.application.config.action_mailer.deliver_later_queue_name)
      end
    end
  end

  describe 'headers for user' do
    context "confirmation email" do
      subject { described_class.confirmation_instructions(user, token, opts = {}) }

      context "legacy domain" do
        it "respect preferred domain" do
          expect(header_value("From", subject.message)).to eq(NO_REPLY_EMAIL)
          expect(header_value("Reply-To", subject.message)).to eq(NO_REPLY_EMAIL)
          expect(subject.message.to_s).to include("#{ENV.fetch("APP_HOST_LEGACY")}/users/confirmation")
        end
      end

      context "new domain" do
        let(:user) { create(:user, preferred_domain: :demarches_gouv_fr) }

        it "respect preferred domain" do
          expect(header_value("From", subject.message)).to eq("Ne pas répondre <ne-pas-repondre@demarches.gouv.fr>")
          expect(header_value("Reply-To", subject.message)).to eq("Ne pas répondre <ne-pas-repondre@demarches.gouv.fr>")
          expect(subject.message.to_s).to include("#{ENV.fetch("APP_HOST")}/users/confirmation")
          expect(subject.message.to_s).to include("//#{ENV.fetch("APP_HOST")}/assets/mailer/republique")
        end
      end
    end
  end

  def header_value(name, message)
    message.header.fields.find { _1.name == name }.value
  end
end
