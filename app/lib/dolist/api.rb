require "support/jsv"

class Dolist::API
  CONTACT_URL = "https://apiv9.dolist.net/v1/contacts/read?AccountID=%{account_id}"
  EMAIL_LOGS_URL = "https://apiv9.dolist.net/v1/statistics/email/sendings/transactional/search?AccountID=%{account_id}"
  EMAIL_KEY = 7
  STATUS_KEY = 72
  DOLIST_WEB_DASHBOARD = "https://campaign.dolist.net/#/%{account_id}/contacts/%{contact_id}/sendings"
  EMAIL_MESSAGES_ADRESSES_REPLIES = "https://apiv9.dolist.net/v1/email/messages/addresses/replies?AccountID=%{account_id}"
  EMAIL_MESSAGES_ADRESSES_PACKSENDERS = "https://apiv9.dolist.net/v1/email/messages/addresses/packsenders?AccountID=%{account_id}"
  EMAIL_SENDING_TRANSACTIONAL = "https://apiv9.dolist.net/v1/email/sendings/transactional?AccountID=%{account_id}"
  EMAIL_SENDING_TRANSACTIONAL_ATTACHMENT = "https://apiv9.dolist.net/v1/email/sendings/transactional/attachment?AccountID=%{account_id}"
  EMAIL_SENDING_TRANSACTIONAL_SEARCH = "https://apiv9.dolist.net/v1/email/sendings/transactional/search?AccountID=%{account_id}"

  class_attribute :limit_remaining, :limit_reset_at

  # those code are just undocumented
  IGNORABLE_API_ERROR_CODE = [
    "458",
    "402"
  ]

  # see: https://usercampaign.dolist.net/wp-content/uploads/2022/12/Comprendre-les-Opt-out-tableau-v2.pdf
  IGNORABLE_CONTACT_STATUSES = [
    "4", # Le serveur distant n'accepte pas le mail car il identifie que l’adresse e-mail est en erreur.
    "7" # Suite à un envoi, le serveur distant accepte le mail dans un premier temps mais envoie une erreur définitive car l’adresse e-mail est en erreur. L'adresse e-mail n’existe pas ou n'existe plus.
  ]

  class << self
    def save_rate_limit_headers(headers)
      self.limit_remaining = headers["X-Rate-Limit-Remaining"].to_i
      self.limit_reset_at = Time.zone.at(headers["X-Rate-Limit-Reset"].to_i / 1_000)
    end

    def near_rate_limit?
      return if limit_remaining.nil?

      limit_remaining < 20 # keep 20 requests for non background API calls
    end

    def sleep_until_limit_reset
      return if limit_reset_at.nil? || limit_reset_at.past?

      sleep (limit_reset_at - Time.zone.now).ceil
    end

    def sendable?(mail)
      return false if mail.to.blank? # recipient are mandatory
      return false if mail.bcc.present? # no bcc support

      # Mail having attachments are not yet supported in our account
      mail.attachments.none? { !_1.inline? }
    end
  end

  def properly_configured?
    client_key.present?
  end

  def send_email(mail)
    if mail.attachments.any? { !_1.inline? }
      return send_email_with_attachment(mail)
    end

    body = { "TransactionalSending": prepare_mail_body(mail) }

    url = format_url(EMAIL_SENDING_TRANSACTIONAL)
    post(url, body.to_json)
  end

  def send_email_with_attachment(mail)
    uri = URI(format_url(EMAIL_SENDING_TRANSACTIONAL_ATTACHMENT))

    request = Net::HTTP::Post.new(uri)

    default_headers.each do |key, value|
      next if key.to_s == "Content-Type"
      request[key] = value
    end

    boundary = "---011000010111000001101001" # any random string not present in the body
    request.content_type = "multipart/form-data; boundary=#{boundary}"

    body = "--#{boundary}\r\n"

    base64_files(mail.attachments).each do |file|
      body << "Content-Disposition: form-data; name=\"#{file.field_name}\"; filename=\"#{file.filename}\"\r\n"
      body << "Content-Type: #{file.mime_type}\r\n"
      body << "\r\n"
      body << file.content
      body << "\r\n"
    end

    body << "\r\n--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"TransactionalSending\"\r\n"
    body << "Content-Type: text/plain; charset=utf-8\r\n"
    body << "\r\n"
    body << prepare_mail_body(mail).to_jsv

    body << "\r\n--#{boundary}--\r\n"
    body << "\r\n"

    request.body = body

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    if response.body.empty?
      fail "Dolist API returned an empty response"
    else
      JSON.parse(response.body)
    end
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

  def senders
    get format_url(EMAIL_MESSAGES_ADRESSES_PACKSENDERS)
  end

  def replies
    get format_url(EMAIL_MESSAGES_ADRESSES_REPLIES)
  end

  # Une adresse e-mail peut ne pas être adressable pour différentes raisons (injoignable, plainte pour spam, blocage d’un FAI).
  # Dans ce cas l’API d’envoi transactionnel renvoie différentes erreurs.
  # Pour connaitre exactement le statut d’une adresse, je vous invite à récupérer le champ 72 du contact à partir de son adresse e-mail avec la méthode https://api.dolist.com/documentation/index.html#/40e7751d00dc3-rechercher-un-contact
  #
  # La liste des différents statuts est disponible sur https://usercampaign.dolist.net/wp-content/uploads/2022/12/Comprendre-les-Opt-out-tableau-v2.pdf
  def fetch_contact_status(email_address)
    url = format(Dolist::API::CONTACT_URL, account_id: account_id)
    body = {
      Query: {
        FieldValueList: [{ ID: 7, Value: email_address }],
        OutputFieldIDList: [72]
      }
    }.to_json

    post(url, body)["FieldList"].find { _1['ID'] == 72 }['Value']
  end

  def ignorable_api_error_code?(api_error_code)
    IGNORABLE_API_ERROR_CODE.include?(api_error_code)
  end

  def ignorable_contact_status?(contact_status)
    IGNORABLE_CONTACT_STATUSES.include?(contact_status)
  end

  private

  def format_url(base)
    format(base, account_id: account_id)
  end

  def sender_id
    Rails.cache.fetch("dolist_api_sender_id", expires_in: 1.hour) do
      senders.dig("ItemList", 0, "Sender", "ID")
    end
  end

  def get(url)
    response = Typhoeus.get(url, headers: default_headers).tap do
      self.class.save_rate_limit_headers(_1.headers)
    end

    JSON.parse(response.response_body)
  end

  def post(url, body)
    response = Typhoeus.post(url, body:, headers: default_headers).tap do
      self.class.save_rate_limit_headers(_1.headers)
    end

    if response.response_body.empty?
      fail "Empty response from Dolist API"
    else
      JSON.parse(response.response_body)
    end
  end

  def default_headers
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

    post(url, body)["ID"]
  end

  # https://api.dolist.com/documentation/index.html#/b3A6Mzg0MTQ4MDk-recuperer-les-statistiques-des-envois-pour-un-contact
  def fetch_dolist_messages(contact_id)
    url = format(EMAIL_LOGS_URL, account_id: account_id)

    body = { SearchQuery: { ContactID: contact_id } }.to_json

    post(url, body)["ItemList"]
  end

  def prepare_mail_body(mail)
    {
      "Type": "TransactionalService",
      "Contact": {
        "FieldList": [
          {
            "ID": EMAIL_KEY,
            "Value": mail.to.first
          }
        ]
      },
      "Message": {
        "Name": mail['X-Dolist-Message-Name'].value,
        "Subject": mail.subject,
        "SenderID": sender_id,
        "ForceHttp": true,
        "Format": "html",
        "DisableOpenTracking": true,
        "IsTrackingValidated": true
      },
      "MessageContent": {
        "SourceCode":  mail_source_code(mail),
        "EncodingType": "UTF8",
        "EnableTrackingDetection": false
      }
    }
  end

  def to_sent_mail(email_address, contact_id, dolist_message)
    SentMail.new(
      from: ENV['DOLIST_NO_REPLY_EMAIL'],
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

  def mail_source_code(mail)
    if mail.html_part.nil? && mail.text_part.nil?
      mail.decoded
    else
      mail.html_part.body.decoded
    end
  end

  def base64_files(attachments)
    attachments.map do |attachment|
      raise ArgumentError, "Dolist API does not support non PDF attachments. Given #{attachment.filename} which has mime_type=#{attachment.mime_type}" unless attachment.mime_type == "application/pdf"

      field_name = File.basename(attachment.filename, File.extname(attachment.filename))
      attachment_content = attachment.body.decoded
      attachment_base64 = Base64.strict_encode64(attachment_content)

      Dolist::Base64File.new(field_name:, filename: attachment.filename, mime_type: attachment.mime_type, content: attachment_base64)
    end
  end
end
