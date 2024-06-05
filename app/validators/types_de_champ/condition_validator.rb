class TypesDeChamp::ConditionValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    public_tdcs = types_de_champ.to_a
      .flat_map { _1.repetition? ? procedure.draft_revision.children_of(_1) : _1 }

    public_tdcs
      .map.with_index
      .filter_map { |tdc, i| tdc.condition? ? [tdc, i] : nil }
      .map do |tdc, i|
        [tdc, tdc.condition.errors(public_tdcs.take(i))]
      end
      .filter { |_tdc, errors| errors.present? }
      .each do |tdc, _error_hash|
        procedure.errors.add(
          attribute,
          procedure.errors.generate_message(attribute, :invalid_condition, { value: tdc.libelle }),
          type_de_champ: tdc
        )
      end
  end
end
