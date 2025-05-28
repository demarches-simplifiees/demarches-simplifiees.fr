# frozen_string_literal: true

class TypesDeChamp::ReferentielReadyValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, types_de_champ)
    types_de_champ.filter(&:referentiel?).each do |referentiel_champ|
      unless referentiel_champ.referentiel&.ready?
        procedure.errors.add(
          attribute,
          procedure.errors.generate_message(attribute, :referentiel_not_ready, { value: referentiel_champ.libelle }),
          type_de_champ: referentiel_champ
        )
      end
    end
  end
end
