# frozen_string_literal: true

RSpec.describe Cron::AdministrateurActivateBeforeExpirationJob, type: :job do
  describe 'perform' do
    let(:administrateur) { administrateurs(:default_admin) }
    let(:user) { administrateur.user }
    let(:mailer_double) { double('mailer', deliver_later: true) }

    subject { Cron::AdministrateurActivateBeforeExpirationJob.perform_now }

    before do
      Timecop.freeze(Time.zone.local(2018, 03, 20))
      administrateur.reload
      allow(AdministrateurMailer).to receive(:activate_before_expiration).and_return(mailer_double)
    end

    after { Timecop.return }

    context "with an inactive administrateur" do
      before { user.update(last_sign_in_at: nil) }

      context "created now" do
        before { subject }
        it { expect(AdministrateurMailer).not_to have_received(:activate_before_expiration) }
      end

      context "created a long time ago" do
        before do
          administrateur.update_columns(created_at: Time.zone.local(2018, 03, 10))
          subject
        end

        it { expect(AdministrateurMailer).not_to have_received(:activate_before_expiration) }
      end

      context "created 3 days ago" do
        before do
          administrateur.update_columns(created_at: Time.zone.local(2018, 03, 17, 20, 00))
          subject
        end

        it { expect(AdministrateurMailer).to have_received(:activate_before_expiration).with(administrateur.user, kind_of(String)) }
      end
    end

    context "with an active administrateur" do
      before { user.update(last_sign_in_at: Time.zone.now) }

      context "created now" do
        before { subject }
        it { expect(AdministrateurMailer).not_to have_received(:activate_before_expiration) }
      end

      context "created a long time ago" do
        before do
          administrateur.update_columns(created_at: Time.zone.local(2018, 03, 10))
          subject
        end

        it { expect(AdministrateurMailer).not_to have_received(:activate_before_expiration) }
      end

      context "created 2 days ago" do
        before do
          administrateur.update_columns(created_at: Time.zone.local(2018, 03, 18, 20, 00))
          subject
        end

        it { expect(AdministrateurMailer).not_to have_received(:activate_before_expiration) }
      end
    end
  end
end
