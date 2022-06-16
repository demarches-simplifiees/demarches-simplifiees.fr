class TypesDeChamp::NoEmptyRepetitionValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.filter(&:repetition?).each do |repetition|
      validate_repetition_not_empty(procedure, attribute, repetition)
    end
  end

  private

  def validate_repetition_not_empty(procedure, attribute, repetition)
    if procedure.draft_revision.children_of(repetition).empty?
      procedure.errors.add(
        attribute,
        procedure.errors.generate_message(attribute, :empty_repetition, { value: repetition.libelle })
      )
    end
  end
end
