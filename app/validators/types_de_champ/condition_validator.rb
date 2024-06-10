class TypesDeChamp::ConditionValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    return if types_de_champ.empty?

    tdcs = if attribute == :draft_types_de_champ_private
      procedure.draft_revision.types_de_champ_for
    else
      procedure.draft_revision.types_de_champ_for(scope: :public)
    end

    tdcs.each_with_index do |tdc, i|
      next unless tdc.condition?

      errors = tdc.condition.errors(tdcs.take(i))
      next if errors.blank?

      procedure.errors.add(
        attribute,
        procedure.errors.generate_message(attribute, :invalid_condition, { value: tdc.libelle }),
        type_de_champ: tdc
      )
    end
  end
end
