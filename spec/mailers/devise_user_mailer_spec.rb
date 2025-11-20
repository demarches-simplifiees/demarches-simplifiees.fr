# frozen_string_literal: true

RSpec.describe DeviseUserMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:token) { SecureRandom.hex }
  describe '.confirmation_instructions' do
    subject { described_class.confirmation_instructions(user, token, opts = {}) }

    context 'without SafeMailer configured' do
      it do
        expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil)
        expect(subject[BalancerDeliveryMethod::BYPASS_UNVERIFIED_MAIL_PROTECTION]).to be_present
      end
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

    describe "i18n" do
      context "when locale is fr" do
        let(:user) { create(:user, locale: :fr) }

        it "uses fr locale" do
          expect(subject.body).to include("Activez votre compte")
        end
      end

      context "when locale is en" do
        let(:user) { create(:user, locale: :en) }

        it "uses en locale" do
          expect(subject.body).to include("Activate account")
        end
      end
    end
  end
end
