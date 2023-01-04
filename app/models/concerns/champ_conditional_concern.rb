module ChampConditionalConcern
  extend ActiveSupport::Concern

  included do
    def conditional?
      type_de_champ.read_attribute_before_type_cast('condition').present?
    end

    def dependent_conditions?
      dossier.revision.dependent_conditions(type_de_champ).any?
    end

    def visible?
      if conditional?
        type_de_champ.condition.compute(champs_for_condition)
      else
        true
      end
    end

    private

    def champs_for_condition
      dossier.champs.filter { _1.row.nil? || _1.row == row }
    end
  end
end
