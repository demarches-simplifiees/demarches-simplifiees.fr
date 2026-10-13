# frozen_string_literal: true

class Brevo::EmailPayload
  # Brevo treats the subject and both bodies as templates, even without params:
  # a champ value `Projet {{ alpha }}` came out as "Projet", and a stray `{{`
  # got the mail accepted (201), then never delivered. Each opening becomes the
  # Pongo2 tag that prints it as is. `{% verbatim %}` would not do: content can
  # close it.
  TEMPLATE_OPENINGS = {
    '{{' => '{% templatetag openvariable %}',
    '{%' => '{% templatetag openblock %}',
    '{#' => '{% templatetag opencomment %}',
  }.freeze

  def initialize(mail)
    @mail = mail
  end

  # Converts the Mail::Message into the JSON body of POST /v3/smtp/email.
  def to_h
    {
      sender: address(@mail[:from].addrs.first),
      subject: literal(@mail.subject),
      htmlContent: literal(@mail.html_part.decoded),
      textContent: literal(@mail.text_part.decoded),
      replyTo: @mail[:reply_to]&.then { address(it.addrs.first) },
      attachment: attachments.presence,
      tags: [@mail[PriorityDeliveryConcern::MAILER_HEADER].value],
      headers: { idempotencyKey: Current.mail_idempotency_key }.compact.presence,
      **recipients,
    }.compact
  end

  private

  # Brevo requires a To: a bcc-only mail becomes one message version per
  # recipient, each with that recipient as its To.
  def recipients
    if @mail.to_addrs.empty?
      { messageVersions: @mail.bcc_addrs.map { { to: [{ email: it }] } } }
    else
      {
        to: emails(@mail.to_addrs),
        cc: emails(@mail.cc_addrs).presence,
        bcc: emails(@mail.bcc_addrs).presence,
      }
    end
  end

  def literal(text) = text.gsub(/\{[{%#]/, TEMPLATE_OPENINGS)

  def emails(addresses) = addresses.map { { email: it } }

  def address(mail_address)
    { email: mail_address.address, name: mail_address.display_name }.compact
  end

  def attachments
    @mail.attachments.map { { name: it.filename, content: Base64.strict_encode64(it.decoded) } }
  end
end
