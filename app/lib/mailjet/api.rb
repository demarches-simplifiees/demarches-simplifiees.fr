class Mailjet::API
  def properly_configured?
    [Mailjet.config.api_key, Mailjet.config.secret_key].all?(&:present?)
  end

  # Get messages sent to a user through SendInBlue.
  #
  # Returns an array of SentMail objects.
  def sent_mails(email_address)
    contact = Mailjet::Contact.find(email_address)
    if contact.nil?
      Rails.logger.info "Mailjet::API: no contact found for email address '#{email_address}'"
      return []
    end

    messages = Mailjet::Message.all(
      contact: contact.attributes['id'],
      from_ts: 30.days.ago.to_datetime.rfc3339,
      show_subject: true
    )

    messages.map do |message|
      SentMail.new(
        from: nil,
        to: email_address,
        subject: message.attributes['subject'],
        delivered_at: message.attributes['arrived_at'],
        status: message.attributes['status'],
        service_name: 'Mailjet',
        external_url: 'https://app.mailjet.com/contacts/subscribers/contact_list'
      )
    end
  rescue Mailjet::ApiError => e
    Rails.logger.error e.message
    []
  end
end
