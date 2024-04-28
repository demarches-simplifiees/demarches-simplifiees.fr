# frozen_string_literal: true

SUPER_ADMIN_OTP_ENABLED = Rails.env.test? || (ENV.fetch("SUPER_ADMIN_OTP_ENABLED", "enabled") == "enabled")
