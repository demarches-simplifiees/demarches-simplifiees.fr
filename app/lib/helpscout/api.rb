class Helpscout::API
  MAILBOXES = 'mailboxes'
  CONVERSATIONS = 'conversations'
  TAGS = 'tags'
  FIELDS = 'fields'
  CUSTOMERS = 'customers'
  PHONES = 'phones'
  OAUTH2_TOKEN = 'oauth2/token'

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

  def create_conversation(email, subject, text, file)
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
          attachments: attachments(file)
        }
      ]
    }.compact

    call_api(:post, CONVERSATIONS, body)
  end

  def add_phone_number(email, phone)
    query = URI.encode("(email:#{email})")
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

  def attachments(file)
    if file.present?
      [
        {
          fileName: file.original_filename,
          mimeType: file.content_type,
          data: Base64.strict_encode64(file.read)
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
