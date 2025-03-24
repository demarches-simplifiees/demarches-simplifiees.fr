# frozen_string_literal: true

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
      # Huge gain perf for cascade conditions
      return @visible if instance_variable_defined? :@visible

      return false if parent_hidden?

      @visible = if conditional?
        type_de_champ.condition.compute(champs_for_condition)
      else
        true
      end
    end

    def reset_visible # recompute after a dossier update
      remove_instance_variable :@visible if instance_variable_defined? :@visible
    end

    private

    def champs_for_condition
      dossier.filled_champs.filter { _1.row_id.nil? || _1.row_id == row_id }
    end

    def parent_hidden?
      parent = dossier.project_champs
        .find { it.type_de_champ == dossier.revision.parent_of(type_de_champ) }

      return false if parent.nil?

      !parent.visible?
    end
  end
end
