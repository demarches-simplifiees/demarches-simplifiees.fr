# frozen_string_literal: true

class TypesDeChamp::FormattedTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def initialize(*args)
    super
    if @type_de_champ.options&.empty?
      @type_de_champ.options = { formatted_mode: 'simple', letters_accepted: true, numbers_accepted: true, special_characters_accepted: true }
    end
  end
end
