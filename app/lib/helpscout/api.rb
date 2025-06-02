# frozen_string_literal: true

class Helpscout::API
  MAILBOXES = 'mailboxes'
  CONVERSATIONS = 'conversations'
  TAGS = 'tags'
  FIELDS = 'fields'
  CUSTOMERS = 'customers'
  PHONES = 'phones'
  OAUTH2_TOKEN = 'oauth2/token'

  RATELIMIT_KEY = "helpscout-rate-limit-remaining"

  def ready?
    required_secrets = [
      Rails.application.secrets.helpscout[:mailbox_id],
      Rails.application.secrets.helpscout[:client_id],
      Rails.application.secrets.helpscout[:client_secret]
    ]
    required_secrets.all?(&:present?)
  end

  def add_tags(conversation_id, tags)
    call_api(:put, "#{CONVERSATIONS}/#{conversation_id}/#{TAGS}", {
      tags: tags
    })
  end

  def create_conversation(email, subject, text, blob)
    body = {
      subject: subject,
      customer: customer(email),
      mailboxId: user_support_mailbox_id,
      type: 'email',
      status: 'active',
      threads: [
        {
          type: 'customer',
          customer: customer(email),
          text: text,
          attachments: attachments(blob)
        }
      ]
    }.compact

    call_api(:post, CONVERSATIONS, body)
  end

  def list_old_conversations(status, before, page: 1)
    body = {
      page:,
      status:, # active, open, closed, pending, spam. "all" does not work
      query: "(
        modifiedAt:[* TO #{before.iso8601}]
      )",
      sortField: "modifiedAt",
      sortOrder: "desc"
    }

    response = call_api(:get, "#{CONVERSATIONS}?#{body.to_query}")
    if !response.success?
      raise StandardError, "Error while listing conversations: #{response.response_code} '#{response.body}'"
    end

    body = parse_response_body(response)
    [body[:_embedded][:conversations], body[:page]]
  end

  def delete_conversation(conversation_id)
    call_api(:delete, "#{CONVERSATIONS}/#{conversation_id}")
  end

  def add_phone_number(email, phone)
    query = CGI.escape("(email:#{email})")
    response = call_api(:get, "#{CUSTOMERS}?mailbox=#{user_support_mailbox_id}&query=#{query}")
    if response.success?
      body = parse_response_body(response)
      if body[:page][:totalElements] > 0
        customer_id = body[:_embedded][:customers].first[:id]
        call_api(:post, "#{CUSTOMERS}/#{customer_id}/#{PHONES}", {
          type: "work",
          value: phone
        })
      end
    end
  end

  def productivity_report(year, month)
    Rails.logger.info("[HelpScout API] Retrieving productivity report for #{month}-#{year}…")

    params = {
      mailboxes: [user_support_mailbox_id].join(','),
      start: Time.utc(year, month).iso8601,
      end: Time.utc(year, month).next_month.iso8601
    }

    response = call_api(:get, 'reports/productivity?' + params.to_query)
    if !response.success?
      raise StandardError, "Error while fetching productivity report: #{response.response_code} '#{response.body}'"
    end

    parse_response_body(response)
  end

  private

  def attachments(blob)
    if blob.present?
      [
        {
          fileName: blob.filename,
          mimeType: blob.content_type,
          data: Base64.strict_encode64(blob.download)
        }
      ]
    else
      []
    end
  end

  def customer(email)
    {
      email: email
    }
  end

  def custom_fields
    @custom_fields ||= get_custom_fields.reduce({}) do |fields, field|
      fields[field[:name].to_sym] = field[:id]
      fields
    end
  end

  def get_custom_fields
    parse_response_body(fetch_custom_fields)[:_embedded][:fields]
  end

  def fetch_custom_fields
    call_api(:get, "#{MAILBOXES}/#{user_support_mailbox_id}/#{FIELDS}")
  end

  def call_api(method, path, body = nil)
    url = "#{HELPSCOUT_API_URL}/#{path}"

    case method
    when :get
      Typhoeus.get(url, {
        headers: headers
      })
    when :post
      Typhoeus.post(url, {
        body: body.to_json,
        headers: headers
      })
    when :put
      Typhoeus.put(url, {
        body: body.to_json,
        headers: headers
      })
    when :delete
      Typhoeus.delete(url, {
        body: body.to_json,
        headers: headers
      })
    end.tap do |response|
      Rails.cache.write(RATELIMIT_KEY, response.headers["X-Ratelimit-Remaining-Minute"], expires_in: 1.minute)
    end
  end

  def parse_response_body(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def user_support_mailbox_id
    Rails.application.secrets.helpscout[:mailbox_id]
  end

  def headers
    {
      'Authorization': "Bearer #{access_token}",
      'Content-Type': 'application/json; charset=UTF-8'
    }
  end

  def access_token
    @access_token ||= get_access_token
  end

  def get_access_token
    parse_response_body(fetch_access_token)[:access_token]
  end

  def fetch_access_token
    Typhoeus.post("#{HELPSCOUT_API_URL}/#{OAUTH2_TOKEN}", body: {
      grant_type: 'client_credentials',
      client_id: Rails.application.secrets.helpscout[:client_id],
      client_secret: Rails.application.secrets.helpscout[:client_secret]
    })
  end
end
