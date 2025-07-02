# frozen_string_literal: true

require 'rails_helper'

describe Cron::TrustedDeviceTokenRenewalJob do
  let!(:token_to_notify) do
    create(:trusted_device_token,
      activated_at: (TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD - 5.days).ago,
      renewal_notified_at: nil)
  end

  subject { described_class.new.perform_now }
  it 'updates renewal_notified_at' do
    expect { subject }.to change { token_to_notify.reload.renewal_notified_at }.from(nil).to be_present
  end
  it 'creates a new trusted device token' do
    expect { subject }.to change { TrustedDeviceToken.count }.by(1)
  end
  it 'if recalled, does not resend mail' do
    expect(InstructeurMailer)
      .to receive(:trusted_device_token_renewal)
      .with(token_to_notify.instructeur, an_instance_of(String))
      .and_return(double(deliver_later: true))
      .once
    described_class.new.perform_now
    described_class.new.perform_now
  end
end
