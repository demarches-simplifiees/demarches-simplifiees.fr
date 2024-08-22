# frozen_string_literal: true

class Expired::MailRateLimiter
  attr_reader :delay, :current_window

  def send_with_delay(mail)
    if current_window_full?
      @delay += @window
    end
    if current_window_full? || current_window_expired?
      @current_window = { started_at: Time.current, sent: 0 }
    end
    @current_window[:sent] += 1

    mail.deliver_later(wait: delay)
  end

  private

  def initialize(limit: 200, window: 10.minutes)
    @limit = limit
    @window = window
    @current_window = { started_at: Time.current, sent: 0 }
    @delay = 0
  end

  def current_window_expired?
    (@current_window[:started_at] + @window).past?
  end

  def current_window_full?
    @current_window[:sent] >= @limit
  end
end
