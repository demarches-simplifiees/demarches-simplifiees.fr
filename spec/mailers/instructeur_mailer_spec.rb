RSpec.describe InstructeurMailer, type: :mailer do
  describe '#send_dossier' do
    let(:sender) { create(:instructeur) }
    let(:recipient) { create(:instructeur) }
    let(:dossier) { create(:dossier) }
    subject { described_class.send_dossier(sender, dossier, recipient) }

    it { expect(subject.body).to include('Bonjour') }

    context 'when perform_later is called' do
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }

      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job(PriorizedMailDeliveryJob).on_queue(custom_queue)
      end
    end
  end

  describe '#send_login_token' do
    let(:user) { create(:instructeur) }
    let(:token) { SecureRandom.hex }
    subject { described_class.send_login_token(user, token) }

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

  describe '#last_week_overview' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier) }
    let(:last_week_overview) do
      procedure_overview = double('po',
        procedure: procedure,
        created_dossiers_count: 0,
        dossiers_en_construction_count: 1,
        old_dossiers_en_construction: [dossier],
        dossiers_en_construction_description: 'desc',
        dossiers_en_instruction_count: 1,
        old_dossiers_en_instruction: [dossier],
        dossiers_en_instruction_description: 'desc')

      {
        start_date: Time.zone.now,
        procedure_overviews: [procedure_overview]
      }
    end

    before { allow(instructeur).to receive(:last_week_overview).and_return(last_week_overview) }

    subject { described_class.last_week_overview(instructeur) }

    it { expect(subject.body).to include('Votre activité hebdomadaire') }

    context 'when the instructeur has no active procedures' do
      let(:procedure) { nil }
      let(:last_week_overview) { nil }

      it 'doesn’t send the email' do
        expect(subject.message).to be_kind_of(ActionMailer::Base::NullMail)
        expect(subject.body).to be_blank
      end
    end

    context 'when perform_later is called' do
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }

      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(custom_queue)
      end
    end
  end
end
