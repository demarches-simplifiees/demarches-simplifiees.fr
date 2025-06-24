# frozen_string_literal: true

class TypesDeChamp::LibelleValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.each do |tdc|
      if tdc.libelle.blank?
        procedure.errors.add(
          attribute,
          procedure.errors.generate_message(attribute, :missing_libelle, { position: tdc.revision_types_de_champ.last.position + 1 }),
          type_de_champ: tdc
        )
      end
    end
  end
end
