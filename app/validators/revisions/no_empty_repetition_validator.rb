class Revisions::NoEmptyRepetitionValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, revision)
    return if revision.nil?

    revision_tdcs = revision.types_de_champ + revision.types_de_champ_private
    repetitions = revision_tdcs.filter(&:repetition?)
    repetitions.each do |repetition|
      validate_repetition_not_empty(procedure, attribute, repetition)
    end
  end

  private

  def validate_repetition_not_empty(procedure, attribute, repetition)
    if repetition.types_de_champ.blank?
      procedure.errors.add(
        attribute,
        procedure.errors.generate_message(attribute, :empty_repetition, { value: repetition.libelle })
      )
    end
  end
end
