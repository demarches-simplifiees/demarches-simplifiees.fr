# frozen_string_literal: true

describe Expired::MailRateLimiter do
  describe 'hits limits' do
    let(:limit) { 10 }
    let(:window) { 2.seconds }
    let(:rate_limiter) { Expired::MailRateLimiter.new(limit:, window:) }
    let(:mail) { DossierMailer.notify_automatic_deletion_to_user([], 'tartampion@france.fr') }

    it 'decreases current_window[:limit]' do
      expect { rate_limiter.send_with_delay(mail) }.to change { rate_limiter.current_window[:sent] }.by(1)
    end

    it 'increases the delay by window when it reaches the max number of call' do
      expect do
        (limit + 1).times { rate_limiter.send_with_delay(mail) }
      end.to change { rate_limiter.delay }.by(window)
    end

    it 'renews current_window when it expires' do
      rate_limiter.send_with_delay(mail)
      travel_to(Time.current + window + 1.second) do
        rate_limiter.send_with_delay(mail)
        expect(rate_limiter.current_window[:sent]).to eq(1)
      end
    end
  end
end
