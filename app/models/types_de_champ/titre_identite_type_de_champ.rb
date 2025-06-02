# frozen_string_literal: true

class TypesDeChamp::TitreIdentiteTypeDeChamp < TypesDeChamp::TypeDeChampBase
  FRANCE_CONNECT = 'france_connect'
  PIECE_JUSTIFICATIVE = 'piece_justificative'

  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  def tags_for_template = [].freeze

  class << self
    def champ_value_for_export(champ, path = :value)
      champ.piece_justificative_file.attached? ? "présent" : "absent"
    end

    def champ_value_for_api(champ, version = 2)
      nil
    end

    def champ_default_export_value(path = :value)
      "absent"
    end
  end
end
