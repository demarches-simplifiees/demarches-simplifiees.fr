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
        let(:user) { create(:user, preferred_domain: :demarche_numerique_gouv_fr) }

        it "respect preferred domain" do
          expect(header_value("From", subject.message)).to eq("Démarche Numérique <ne-pas-repondre@demarche.numerique.gouv.fr>")
          expect(header_value("Reply-To", subject.message)).to eq("Démarche Numérique <ne-pas-repondre@demarche.numerique.gouv.fr>")
          expect(subject.message.to_s).to include("demarche.numerique.gouv.fr/users/confirmation")
          expect(subject.message.to_s).to include("//demarche.numerique.gouv.fr/assets/")
        end
      end
    end

    context "reset password instructions" do
      subject { described_class.reset_password_instructions(user, token) }

      context "legacy domain" do
        it "respect preferred domain" do
          expect(header_value("From", subject.message)).to include(CONTACT_EMAIL)
          expect(subject.message.to_s).to include("#{ENV.fetch("APP_HOST_LEGACY")}/users/password")
          expect(subject[BalancerDeliveryMethod::BYPASS_UNVERIFIED_MAIL_PROTECTION]).to be_present
        end
      end

      context "new domain" do
        let(:user) { create(:user, preferred_domain: :demarche_numerique_gouv_fr) }

        it "respect preferred domain" do
          expect(header_value("From", subject.message)).to include("@demarche.numerique.gouv.fr")
          expect(subject.message.to_s).to include("demarche.numerique.gouv.fr/users/password")
        end
      end
    end
  end
end
