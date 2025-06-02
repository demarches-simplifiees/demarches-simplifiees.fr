# frozen_string_literal: true

# Represent an email sent using an external API
class SentMail < Struct.new(:from, :to, :subject, :delivered_at, :status, :service_name, :external_url, keyword_init: true)
end
