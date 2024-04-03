class Webhook < ApplicationRecord
  has_secure_token :secret
  belongs_to :procedure
  has_many :events, class_name: 'WebhookEvent', dependent: :destroy, inverse_of: :webhook

  EVENT_TYPES = {
    dossier_depose: 'dossier_déposé',
    dossier_corrige: 'dossier_corrigé',
    dossier_passe_en_instruction: 'dossier_passé_en_instruction',
    dossier_repasse_en_construction: 'dossier_repassé_en_construction',
    dossier_repasse_en_instruction: 'dossier_repassé_en_instruction',
    dossier_accepte: 'dossier_accepté',
    dossier_refuse: 'dossier_refusé',
    dossier_classe_sans_suite: 'dossier_classé_sans_suite',
    dossier_termine: 'dossier_terminé',
    dossier_avis_rendu: 'dossier_avis_rendu',
    dossier_message_recu: 'dossier_message_reçu'
  }

  enum event_types: EVENT_TYPES

  TIMEOUT = 10

  scope :enabled, -> { where(enabled: true) }
  scope :with_event_type, -> (event_type) { where("event_type @> ARRAY[?]::varchar[]", Array.wrap(event_type)) }

  def self.enqueue(dossier, event_type)
    dossier.procedure.webhooks.enabled.with_event_type(event_type).map do |webhook|
      event = webhook.events.create!(enqueued_at: Time.zone.now,
        event_type: Array.wrap(event_type),
        resource_type: 'Dossier',
        resource_id: dossier.to_typed_id,
        resource_version: dossier.revision_id.to_s)

      DeliverWebhookJob.deliver_later(webhook, event)
    end
  end

  def deliver(data)
    return :cancel unless enabled?

    response = Typhoeus.post(url, headers:, body: data.to_json, timeout: TIMEOUT)

    if response.success?
      self.last_success_at = Time.zone.now

      save!
      :success
    else
      self.last_error_at = Time.zone.now
      self.enabled = alive?
      self.last_error_message = format_error_message(response)

      save!
      if enabled?
        :error
      else
        :cancel
      end
    end
  end

  private

  def alive?
    (last_success_at || created_at) > 2.days.ago
  end

  def headers
    {
      'content-type': 'application/json',
      'authorization': "Bearer #{secret}"
    }
  end

  def format_error_message(response)
    connect_time = response.connect_time
    curl_message = response.return_message
    http_error_code = response.code
    datetime = response.headers.fetch('Date', DateTime.current.inspect)
    total_time = response.total_time

    uri = URI.parse(response.effective_url)
    url = "#{uri.host}#{uri.path}"

    msg = <<~TEXT
      url: #{url}
      HTTP error code: #{http_error_code}
      #{response.body.force_encoding('UTF-8')}
      curl message: #{curl_message}
      total time: #{total_time}
      connect time: #{connect_time}
      datetime: #{datetime}
    TEXT

    msg
  end
end
