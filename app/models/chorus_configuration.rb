class ChorusConfiguration
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :centre_de_coup, :json, default: '{}'
  attribute :domaine_fonctionnel, :json, default: '{}'
  attribute :referentiel_de_programmation, :json, default: '{}'

  def format_displayed_value(attribute_name)
    case attribute_name
    when :centre_de_coup
      ChorusConfiguration.format_centre_de_coup_label(centre_de_coup)
    when :domaine_fonctionnel
      ChorusConfiguration.format_domaine_fonctionnel_label(domaine_fonctionnel)
    when :referentiel_de_programmation
      ChorusConfiguration.format_ref_programmation_label(referentiel_de_programmation)
    else
      raise 'unknown attribute_name'
    end
  end

  def format_hidden_value(attribute_name)
    case attribute_name
    when :centre_de_coup
      centre_de_coup.to_json
    when :domaine_fonctionnel
      domaine_fonctionnel.to_json
    when :referentiel_de_programmation
      referentiel_de_programmation.to_json
    else
      raise 'unknown attribute_name'
    end
  end

  def self.format_centre_de_coup_label(api_result)
    return "" if api_result.blank?
    api_result = api_result.symbolize_keys
    "#{api_result[:description]} - #{api_result[:code]}"
  end

  def self.format_domaine_fonctionnel_label(api_result)
    return "" if api_result.blank?
    api_result = api_result.symbolize_keys
    "#{api_result[:label]} - #{api_result[:code]}"
  end

  def self.format_ref_programmation_label(api_result)
    return "" if api_result.blank?
    api_result = api_result.symbolize_keys
    "#{api_result[:label]} - #{api_result[:code]}"
  end

  def complete?
    [
      centre_de_coup,
      domaine_fonctionnel,
      referentiel_de_programmation
    ].all?(&:present?)
  end
end
