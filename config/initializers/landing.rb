# frozen_string_literal: true

# Hide or show the landing page sections
LANDING_TESTIMONIALS_ENABLED = ENV.fetch("LANDING_TESTIMONIALS_ENABLED", "enabled") == "enabled"
LANDING_USERS_ENABLED = ENV.fetch("LANDING_USERS_ENABLED", "enabled") == "enabled"
