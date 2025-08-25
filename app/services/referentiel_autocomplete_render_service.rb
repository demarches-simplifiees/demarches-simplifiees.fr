# frozen_string_literal: true

class ReferentielAutocompleteRenderService
  attr_reader :api_response, :referentiel, :json_template

  def initialize(api_response, referentiel)
    @api_response = api_response.with_indifferent_access
    @referentiel = referentiel
    @json_template = referentiel.json_template
  end

  def format_response
    objects = JsonPath.on(api_response, referentiel.datasource).first
    objects.map do |data|
      label = render_template(json_template, data).join("")
      {
        label:,
        value: label,
        data: message_encryptor_service.encrypt_and_sign(data, purpose: :storage, expires_in: 1.hour)
      }
    end
  end

  private

  def message_encryptor_service
    @message_encryptor_service ||= MessageEncryptorService.new
  end

  def render_template(template, obj, interpolations = [])
    case template["type"]
    when "mention"
      interpolations << JsonPath.on(obj, template["attrs"]["id"]).first
    when "text"
      interpolations << template["text"]
    when "doc", 'paragraph'
      template['content'].each { |t| interpolations.concat(render_template(t, obj)) }
    else
      fail "unknown template #{template['type']}"
    end
    interpolations
  end
end
