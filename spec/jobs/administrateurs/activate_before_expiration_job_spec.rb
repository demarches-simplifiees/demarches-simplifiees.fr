require 'rails_helper'

RSpec.describe Administrateurs::ActivateBeforeExpirationJob, type: :job do
  describe 'perform' do
    let(:administrateur) { create(:administrateur, active: active) }
    let(:mailer_double) { double('mailer', deliver_later: true) }

    subject { Administrateurs::ActivateBeforeExpirationJob.perform_now }

    before do
      Timecop.freeze(Time.zone.local(2018, 03, 20))
      administrateur.reload
      allow(AdministrateurMailer).to receive(:activate_before_expiration).and_return(mailer_double)
    end

    after { Timecop.return }

    context "with an inactive administrateur" do
      let(:active) { false }

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

        it { expect(AdministrateurMailer).to have_received(:activate_before_expiration).with(administrateur, kind_of(String)) }
      end
    end

    context "with an active administrateur" do
      let(:active) { true }

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
