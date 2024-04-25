RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user) }

  describe '.new_account_warning' do
    subject { described_class.new_account_warning(user) }

    it { expect(subject.to).to eq([user.email]) }
    it { expect(subject.body).to include(user.email) }
    it { expect(subject.body).to have_link('J’ai oublié mon mot de passe') }

    context 'when a procedure is provided' do
      let(:procedure) { build(:procedure) }

      subject { described_class.new_account_warning(user, procedure) }

      it { expect(subject.body).to have_link("Commencer la démarche « #{procedure.libelle} »", href: commencer_sign_in_url(path: procedure.path)) }
    end

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

  describe '.ask_for_merge' do
    let(:requested_email) { 'new@exemple.fr' }

    subject { described_class.ask_for_merge(user, requested_email) }

    it { expect(subject.to).to eq([requested_email]) }
    it { expect(subject.body).to include(requested_email) }

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

  describe '.france_connect_merge_confirmation' do
    let(:email) { 'new.exemple.fr' }
    let(:code) { '123456' }

    subject { described_class.france_connect_merge_confirmation(email, code, 15.minutes.from_now) }

    it { expect(subject.to).to eq([email]) }
    it { expect(subject.body).to include(france_connect_particulier_mail_merge_with_existing_account_url(email_merge_token: code)) }

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

  describe '.send_archive' do
    let(:procedure) { create(:procedure) }
    let(:archive) { create(:archive) }
    subject { described_class.send_archive(role, procedure, archive) }

    context 'instructeur' do
      let(:role) { create(:instructeur) }
      it { expect(subject.to).to eq([role.user.email]) }
      it { expect(subject.body).to have_link('Consulter mes archives', href: instructeur_archives_url(procedure)) }
      it { expect(subject.body).to have_link("#{procedure.id} − #{procedure.libelle}", href: instructeur_procedure_url(procedure)) }
    end

    context 'instructeur' do
      let(:role) { create(:administrateur) }
      it { expect(subject.to).to eq([role.user.email]) }
      it { expect(subject.body).to have_link('Consulter mes archives', href: admin_procedure_archives_url(procedure)) }
      it { expect(subject.body).to have_link("#{procedure.id} − #{procedure.libelle}", href: admin_procedure_url(procedure)) }
    end

    context 'when perform_later is called' do
      let(:role) { create(:administrateur) }
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }
      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(custom_queue)
      end
    end
  end

  describe '.notify_inactive_close_to_deletion' do
    subject { described_class.notify_inactive_close_to_deletion(user) }

    it { expect(subject.to).to eq([user.email]) }
    it { expect(subject.body).to include("Cela fait plus de deux ans que vous ne vous êtes pas connecté à #{APPLICATION_NAME}.") }

    context 'when perform_later is called' do
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }
      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(custom_queue)
      end
    end
  end

  describe '.notify_after_closing' do
    let(:procedure) { create(:procedure) }
    let(:content) { "Bonjour,\r\nsaut de ligne" }
    subject { described_class.notify_after_closing(user, content, procedure) }

    it { expect(subject.to).to eq([user.email]) }
    it { expect(subject.body).to include("Clôture d&#39;une démarche sur Démarches simplifiées") }
    it { expect(subject.body).to include("Bonjour,\r\n<br />saut de ligne") }

    context 'when perform_later is called' do
      let(:custom_queue) { 'low_priority' }
      before { ENV['BULK_EMAIL_QUEUE'] = custom_queue }
      it 'enqueues email is custom queue for low priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(custom_queue)
      end
    end
  end
end
