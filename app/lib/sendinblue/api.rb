# frozen_string_literal: true

class Sendinblue::API
  def self.new_properly_configured!
    api = self.new
    if !api.properly_configured?
      raise StandardError, 'Sendinblue API is not properly configured'
    end
    api
  end

  def initialize
    @failures = []
  end

  def properly_configured?
    client_key.present?
  end

  def update_contact(email, attributes = {})
    # TODO: refactor this to use the official SiB SDK (by using contact create + attributes)
    req = post_api_request('contacts', email: email, attributes: attributes, updateEnabled: true)
    req.on_complete do |response|
      if !response.success?
        push_failure("Error while updating identity for administrateur '#{email}' in Sendinblue: #{response.response_code} '#{response.body}'")
      end
    end
    hydra.queue(req)
  end

  # Get messages sent to a user through SendInBlue.
  #
  # Returns an array of SentMail objects.
  def sent_mails(email_address)
    client = ::SibApiV3Sdk::TransactionalEmailsApi.new
    @events = client.get_email_event_report(email: email_address, days: 30).events

    if @events.blank?
      Rails.logger.info "SendInBlue::API: no messages found for email address '#{email_address}'"
      return []
    end

    @events.group_by(&:message_id).values.map do |message_events|
      latest_event = message_events.first
      SentMail.new(
        from: latest_event.from,
        to: latest_event.email,
        subject: latest_event.subject,
        delivered_at: parse_date(latest_event.date),
        status: latest_event.event,
        service_name: 'SendInBlue',
        external_url: 'https://app-smtp.sendinblue.com/log'
      )
    end
  rescue ::SibApiV3Sdk::ApiError => e
    Rails.logger.error e.message
    []
  end

  def delete_events(day, opts = {})
    client = ::SibApiV3Sdk::TransactionalEmailsApi.new
    event_opts = { start_date: day, end_date: day, limit: 100 }.merge(opts)
    while (events = client.get_email_event_report(event_opts).events).present?
      message_ids = events.map(&:message_id).uniq
      message_ids.each do |message_id|
        client.smtp_log_message_id_delete(message_id)
      end
    end
    true
  rescue ::SibApiV3Sdk::ApiError => e
    Rails.logger.error e.message
    false
  end

  def unblock_user(email_address)
    client = ::SibApiV3Sdk::TransactionalEmailsApi.new
    client.smtp_blocked_contacts_email_delete(email_address)
    true
  rescue ::SibApiV3Sdk::ApiError => e
    Rails.logger.error e.message
    false
  end

  def run
    hydra.run
    @hydra = nil
    flush_failures
  end

  private

  def hydra
    @hydra ||= Typhoeus::Hydra.new(max_concurrency: 50)
  end

  def push_failure(failure)
    @failures << failure
  end

  def flush_failures
    failures = @failures
    @failures = []
    if failures.present?
      raise StandardError, failures.join(', ')
    end
  end

  def post_api_request(path, body)
    url = "#{SENDINBLUE_API_V3_URL}/#{path}"

    Typhoeus::Request.new(
      url,
      method: :post,
      body: body.to_json,
      headers: headers
    )
  end

  def headers
    {
      'api-key': client_key,
      'Content-Type': 'application/json; charset=UTF-8',
    }
  end

  def client_key
    ENV.fetch("SENDINBLUE_API_V3_KEY")
  end

  def parse_date(date)
    date.is_a?(String) ? Time.zone.parse(date) : date
  end
end
