# frozen_string_literal: true

class TypesDeChamp::FormattedTypeDeChamp < TypesDeChamp::TypeDeChampBase
  OPTIONS = %w[
    formatted_mode
    letters_accepted
    numbers_accepted
    special_characters_accepted
    min_character_length
    max_character_length
    expression_reguliere
    expression_reguliere_indications
    expression_reguliere_exemple_text
    expression_reguliere_error_message
  ].freeze

  def initialize(*args)
    super
    if @type_de_champ.options&.empty?
      @type_de_champ.options = { formatted_mode: 'simple', letters_accepted: true, numbers_accepted: true, special_characters_accepted: true }
    end
  end
end
