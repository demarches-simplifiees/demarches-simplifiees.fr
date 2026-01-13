# frozen_string_literal: true

# Concern pour benchmark: version optimisée de stable_id
module ProcedureRevisionTypeDeChampOptimized
  extend ActiveSupport::Concern

  def stable_id
    @stable_id ||= type_de_champ.stable_id
  end
end
