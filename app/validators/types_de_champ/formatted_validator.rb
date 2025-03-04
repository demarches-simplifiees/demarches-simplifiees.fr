# frozen_string_literal: true

class TypesDeChamp::FormattedValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.to_a
      .flat_map { _1.repetition? ? procedure.draft_revision.children_of(_1) : _1 }
      .filter(&:formatted?)
      .each do |tdc|
        validate_characters_rules(procedure, attribute, tdc)
        validate_character_length(procedure, attribute, tdc)
      end
  end

  private

  def validate_characters_rules(procedure, attribute, tdc)
    if tdc.formatted_mode == 'simple' &&
        tdc.letters_accepted == '0' &&
        tdc.numbers_accepted == '0' &&
        tdc.special_characters_accepted == '0'
      procedure.errors.add(
        attribute,
        :invalid_character_rules,
        type_de_champ: tdc
      )
    end
  end

  def validate_character_length(procedure, attribute, tdc)
    if tdc.formatted_mode == 'simple' &&
        tdc.max_character_length.present? &&
        tdc.min_character_length.present? &&
        (tdc.min_character_length.to_i > tdc.max_character_length.to_i)
      procedure.errors.add(
        attribute,
        :invalid_character_length,
        type_de_champ: tdc
      )
    end
  end
end
