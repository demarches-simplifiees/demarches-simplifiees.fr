class TypesDeChamp::LinkedDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  PRIMARY_PATTERN = /^--(.*)--$/

  delegate :drop_down_list_options, to: :@type_de_champ
  validate :check_presence_of_primary_options

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Primaire)",
      description: "#{description} (Primaire)",
      path: :primaire,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Secondaire)",
      description: "#{description} (Secondaire)",
      path: :secondaire,
      maybe_null: public? && !mandatory?
    })
    paths
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

  private

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
