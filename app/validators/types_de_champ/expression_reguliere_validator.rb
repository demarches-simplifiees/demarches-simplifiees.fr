class TypesDeChamp::ExpressionReguliereValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.to_a
      .flat_map { _1.repetition? ? procedure.draft_revision.children_of(_1) : _1 }
      .each do |tdc|
      if tdc.expression_reguliere? && tdc.invalid_regexp?
        # Pf DS next line crashes the page when there's an error
        # procedure.errors.add(:expression_reguliere, type_de_champ: tdc)
        # pf replaced previous line by this based on drop_down mecanism
        procedure.errors.add(
          attribute,
          tdc.errors.map(&:message).join(","),
          type_de_champ: tdc
        )
      end
    end
  end
end
