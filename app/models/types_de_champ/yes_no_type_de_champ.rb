# frozen_string_literal: true

class TypesDeChamp::YesNoTypeDeChamp < TypesDeChamp::CheckboxTypeDeChamp
  def filter_to_human(filter_value)
    if filter_value == "true"
      I18n.t('activerecord.attributes.type_de_champ.type_champs.yes_no_true')
    elsif filter_value == "false"
      I18n.t('activerecord.attributes.type_de_champ.type_champs.yes_no_false')
    else
      filter_value
    end
  end

  class << self
    def champ_value(champ)
      champ_formatted_value(champ)
    end

    def champ_value_for_tag(champ, path = :value)
      champ_formatted_value(champ)
    end

    def champ_value_for_export(champ, path = :value)
      champ_formatted_value(champ)
    end

    def champ_value_for_api(champ, version = 2)
      case version
      when 2
        champ.true? ? 'true' : 'false'
      else
        super
      end
    end

    def champ_default_value
      'Non'
    end

    def champ_default_export_value(path = :value)
      'Non'
    end

    def champ_default_api_value(version = 2)
      case version
      when 2
        'false'
      else
        nil
      end
    end

    private

    def champ_formatted_value(champ)
      champ.true? ? 'Oui' : 'Non'
    end
  end
end
