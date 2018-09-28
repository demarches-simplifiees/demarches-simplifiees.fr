class TypesDeChamp::LinkedDropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  PRIMARY_PATTERN = /^--(.*)--$/

  delegate :drop_down_list, to: :@type_de_champ

  validate :check_presence_of_primary_options

  def primary_options
    primary_options = unpack_options.map(&:first)
    if primary_options.present?
      primary_options.unshift('')
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

  def check_presence_of_primary_options
    if !PRIMARY_PATTERN.match?(drop_down_list.options.second)
      errors.add(libelle, "doit commencer par une entrée de menu primaire de la forme <code style='white-space: pre-wrap;'>--texte--</code>")
    end
  end

  def unpack_options
    _, *options = drop_down_list.options
    chunked = options.slice_before(PRIMARY_PATTERN)
    chunked.map do |chunk|
      primary, *secondary = chunk
      secondary.unshift('')
      [PRIMARY_PATTERN.match(primary)&.[](1), secondary]
    end
  end
end
