class TypesDeChamp::ExpressionReguliereValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.to_a
      .flat_map { _1.repetition? ? procedure.draft_revision.children_of(_1) : _1 }
      .each do |tdc|
      if tdc.expression_reguliere? && tdc.invalid_regexp?
        procedure.errors.add(:expression_reguliere, type_de_champ: tdc)
      end
    end
  end
end
