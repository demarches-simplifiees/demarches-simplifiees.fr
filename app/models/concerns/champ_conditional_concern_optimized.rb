# frozen_string_literal: true

# Concern pour benchmark: version optimisée de champs_for_condition
module ChampConditionalConcernOptimized
  extend ActiveSupport::Concern

  included do
    def reset_visible # recompute after a dossier update
      remove_instance_variable :@visible if instance_variable_defined? :@visible
      remove_instance_variable :@champs_for_condition if instance_variable_defined? :@champs_for_condition
    end
  end

  private

  def champs_for_condition
    compute_champs_for_condition[row_id]
  end

  def compute_champs_for_condition
    @champs_for_condition ||= dossier.filled_champs.group_by(&:row_id)
  end
end
