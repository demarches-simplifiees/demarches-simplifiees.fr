# frozen_string_literal: true

class TypesDeChamp::NoEmptyBlockValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.filter(&:block?).each do |repetition|
      validate_block_not_empty(procedure, attribute, repetition)
    end
  end

  private

  def validate_block_not_empty(procedure, attribute, parent)
    if procedure.draft_revision.children_of(parent).empty?
      procedure.errors.add(
        attribute,
        procedure.errors.generate_message(attribute, :empty_repetition, { value: parent.libelle }),
        type_de_champ: parent
      )
    end
  end
end
