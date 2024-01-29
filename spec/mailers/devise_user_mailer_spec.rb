RSpec.describe DeviseUserMailer, type: :mailer do
  let(:user) { build(:user) }
  let(:token) { SecureRandom.hex }

  describe '.confirmation_instructions' do
    subject { described_class.confirmation_instructions(user, token) }

    context 'without SafeMailer configured' do
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(nil) }
    end

    context 'with SafeMailer configured' do
      let(:forced_delivery_method) { :kikoo }
      before { allow(SafeMailer).to receive(:forced_delivery_method).and_return(forced_delivery_method) }
      it { expect(subject[BalancerDeliveryMethod::FORCE_DELIVERY_METHOD_HEADER]&.value).to eq(forced_delivery_method.to_s) }
    end

    context 'when perform_later is called' do
      let(:user) { create(:user) }
      it 'enqueues email in default queue for high priority delivery' do
        expect { subject.deliver_later }.to have_enqueued_job.on_queue(Rails.application.config.action_mailer.deliver_later_queue_name)
      end
    end

    context 'when user.locale is fr' do
      let(:user) { build(:user, locale: :fr) }

      it 'enqueues email in default queue for high priority delivery' do
        expect(subject.subject).to eq('Instructions de confirmation')
      end
    end

    context 'when user.locale is en' do
      let(:user) { build(:user, locale: :en) }

      it 'i18n content' do
        expect(subject.subject).to eq("Confirmation instructions")
      end
    end
  end

  describe '.reset_password_instructions' do
    subject { DeviseUserMailer.reset_password_instructions(user, 'faketoken') }

    context 'with user.locale fr' do
      let(:user) { build(:user, locale: 'fr') }
      it 'uses fr subject' do
        expect(subject.subject).to eq("Instructions pour changer le mot de passe")
      end
    end

    context 'with user.locale en' do
      let(:user) { build(:user, locale: 'en') }
      it 'uses fr subject' do
        expect(subject.subject).to eq("Reset password instructions")
      end
    end
  end

  describe '.unlock_instructions' do
    subject { DeviseUserMailer.unlock_instructions(user, 'faketoken') }
    context 'with user.locale fr' do
      let(:user) { build(:user, locale: 'fr') }
      it 'uses fr subject' do
        expect(subject.subject).to eq('Instructions pour déverrouiller le compte')
      end
    end
    context 'with user.locale en' do
      let(:user) { build(:user, locale: 'en') }
      it 'uses fr subject' do
        expect(subject.subject).to eq('Unlock instructions')
      end
    end
  end

  describe '.email_changed' do
    subject { DeviseUserMailer.email_changed(user) }

    context 'with user.locale fr' do
      let(:user) { build(:user, locale: 'fr') }
      it 'uses fr subject' do
        expect(subject.subject).to eq('Courriel modifié')
      end
    end

    context 'with user.locale en' do
      let(:user) { build(:user, locale: 'en') }
      it 'uses fr subject' do
        expect(subject.subject).to eq('Email Changed')
      end
    end
  end

  describe '.password_change' do
    subject { DeviseUserMailer.password_change(user) }

    context 'with user.locale fr' do
      let(:user) { build(:user, locale: 'fr') }
      it 'uses fr subject' do
        expect(subject.subject).to eq('Mot de passe modifié')
      end
    end

    context 'with user.locale en' do
      let(:user) { build(:user, locale: 'en') }
      it 'uses fr subject' do
        expect(subject.subject).to eq('Password Changed')
      end
    end
  end
end
