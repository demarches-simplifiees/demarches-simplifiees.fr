class Dolist::API
  CONTACT_URL = "https://apiv9.dolist.net/v1/contacts/read?AccountID=%{account_id}"
  EMAIL_LOGS_URL = "https://apiv9.dolist.net/v1/statistics/email/sendings/transactional/search?AccountID=%{account_id}"
  EMAIL_KEY = 7
  DOLIST_WEB_DASHBOARD = "https://campaign.dolist.net/#/%{account_id}/contacts/%{contact_id}/sendings"

  def properly_configured?
    client_key.present?
  end

  def sent_mails(email_address)
    contact_id = fetch_contact_id(email_address)
    if contact_id.nil?
      Rails.logger.info "Dolist::API: no contact found for email address '#{email_address}'"
      return []
    end

    dolist_messages = fetch_dolist_messages(contact_id)

    dolist_messages.map { |m| to_sent_mail(email_address, contact_id, m) }
  rescue StandardError => e
    Rails.logger.error e.message
    []
  end

  private

  def headers
    {
      "Content-Type": 'application/json',
      "Accept": 'application/json',
      "X-API-Key": client_key
    }
  end

  def client_key
    Rails.application.secrets.dolist[:api_key]
  end

  def account_id
    Rails.application.secrets.dolist[:account_id]
  end

  # https://api.dolist.com/documentation/index.html#/b3A6Mzg0MTQ0MDc-rechercher-un-contact
  def fetch_contact_id(email_address)
    url = format(CONTACT_URL, account_id: account_id)

    body = {
      Query: { FieldValueList: [{ ID: EMAIL_KEY, Value: email_address }] }
    }.to_json

    response = Typhoeus.post(url, body: body, headers: headers)

    JSON.parse(response.response_body)["ID"]
  end

  # https://api.dolist.com/documentation/index.html#/b3A6Mzg0MTQ4MDk-recuperer-les-statistiques-des-envois-pour-un-contact
  def fetch_dolist_messages(contact_id)
    url = format(EMAIL_LOGS_URL, account_id: account_id)

    body = { SearchQuery: { ContactID: contact_id } }.to_json

    response = Typhoeus.post(url, body: body, headers: headers)

    JSON.parse(response.response_body)['ItemList']
  end

  def to_sent_mail(email_address, contact_id, dolist_message)
    SentMail.new(
      from: CONTACT_EMAIL,
      to: email_address,
      subject: dolist_message['SendingName'],
      delivered_at: Time.zone.parse(dolist_message['SendDate']),
      status: status(dolist_message),
      service_name: 'Dolist',
      external_url: format(DOLIST_WEB_DASHBOARD, account_id: account_id, contact_id: contact_id)
    )
  end

  def status(dolist_message)
    case dolist_message.fetch_values('Status', 'IsDelivered')
    in ['Sent', true]
      "delivered"
    in ['Sent', false]
      "sent (delivered ?)"
    in [status, _]
      status
    end
  end
end
