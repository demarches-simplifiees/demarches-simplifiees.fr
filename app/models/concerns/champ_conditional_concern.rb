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

    def submitted_filled?
      return false if dossier.submitted_revision_id.blank?
      return false if dossier.submitted_revision_id == dossier.revision_id

      !type_de_champ.champ_blank?(self)
    end

    def reset_visible # recompute after a dossier update
      remove_instance_variable :@visible if instance_variable_defined? :@visible
    end

    # FIXME we need this for compatibility with new champs tree
    def set_visibility(visible)
      @visible = visible
    end

    private

    def champs_for_condition
      dossier.filled_champs.filter { _1.row_id.nil? || _1.row_id == row_id }
    end

    def parent_hidden?
      # if there is no row_id, it always has been a root champ
      return false if !child?

      # otherwise maybe the champ has been moved outside a repetition
      parent_tdc = dossier.revision.parent_of(type_de_champ)

      return false if parent_tdc.nil?

      parent = dossier.project_champs
        .find { it.type_de_champ == parent_tdc }

      !parent.visible?
    end
  end
end
