# frozen_string_literal: true

RSpec.describe AdministrateurMailer, type: :mailer do
  let(:procedure) { create(:procedure) }
  let(:admin_email) { 'administrateur@email.fr' }

  describe '.notify_procedure_expires_when_termine_forced' do
    subject { described_class.notify_procedure_expires_when_termine_forced(admin_email, procedure) }

    it { expect(subject.to).to eq([admin_email]) }
    it { expect(subject.subject).to include("La suppression automatique des dossiers a été activée sur la démarche") }

    context 'when perform_later is called' do
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }
      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(custom_queue)
      end
    end
  end

  describe '.activate_before_expiration' do
    let(:user) { create(:user, reset_password_sent_at: 2.days.ago) }
    let(:token) { SecureRandom.hex }
    subject { described_class.activate_before_expiration(user, token) }

    context 'without SafeMailer configured' do
      it do
        expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil)
        expect(subject['BYPASS_UNVERIFIED_MAIL_PROTECTION']).to be_present
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
  end

  describe '.notify_service_without_siret' do
    subject { described_class.notify_service_without_siret(admin_email) }

    it { expect(subject.to).to eq([admin_email]) }
    it { expect(subject.subject).to eq("Numéro TAHITI manquant sur un de vos services") }
    it { expect(subject.body).to include("un de vos services n'a pas son numéro TAHITI renseigné") }

    context 'when perform_later is called' do
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }
      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(custom_queue)
      end
    end
  end
end
