# frozen_string_literal: true

class TypesDeChamp::LinkedDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  PRIMARY_PATTERN = /^--(.*)--$/

  delegate :drop_down_list_options, to: :@type_de_champ
  validate :check_presence_of_primary_options

  def libelles_for_export
    path = paths.first
    [[path[:libelle], path[:path]]]
  end

  def add_blank_option_when_not_mandatory(options)
    return options if mandatory
    options.unshift('')
  end

  def primary_options
    primary_options = unpack_options.map(&:first)
    if primary_options.present?
      primary_options = add_blank_option_when_not_mandatory(primary_options)
    end
    primary_options
  end

  def secondary_options
    secondary_options = unpack_options.to_h
    if secondary_options.present?
      secondary_options[''] = []
    end
    secondary_options
  end

  class << self
    def champ_value(champ)
      [champ.primary_value, champ.secondary_value].filter(&:present?).join(' / ')
    end

    def champ_value_for_tag(champ, path = :value)
      case path
      when :primary
        champ.primary_value
      when :secondary
        champ.secondary_value
      when :value
        champ_value(champ)
      end
    end

    def champ_value_for_export(champ, path = :value)
      case path
      when :primary
        champ.primary_value
      when :secondary
        champ.secondary_value
      when :value
        "#{champ.primary_value || ''};#{champ.secondary_value || ''}"
      end
    end

    def champ_value_for_api(champ, version = 2)
      case version
      when 1
        { primary: champ.primary_value, secondary: champ.secondary_value }
      else
        super
      end
    end
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle}/primaire",
      description: "#{description} (Primaire)",
      path: :primary,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle}/secondaire",
      description: "#{description} (Secondaire)",
      path: :secondary,
      maybe_null: public? && !mandatory?
    })
    paths
  end

  def unpack_options
    _, *options = drop_down_list_options
    chunked = options.slice_before(PRIMARY_PATTERN)
    chunked.map do |chunk|
      primary, *secondary = chunk
      secondary = add_blank_option_when_not_mandatory(secondary)
      [PRIMARY_PATTERN.match(primary)&.[](1), secondary]
    end
  end

  def check_presence_of_primary_options
    if !PRIMARY_PATTERN.match?(drop_down_list_options.second)
      errors.add(libelle.presence || "La liste", "doit commencer par une entrée de menu primaire de la forme <code style='white-space: pre-wrap;'>--texte--</code>")
    end
  end
end
