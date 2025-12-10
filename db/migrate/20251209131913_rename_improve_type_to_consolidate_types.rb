# frozen_string_literal: true

class RenameImproveTypeToConsolidateTypes < ActiveRecord::Migration[7.2]
  def up
    LLMRuleSuggestion.where(rule: 'improve_type').update_all(rule: 'consolidate_types')
  end

  def down
    LLMRuleSuggestion.where(rule: 'consolidate_types').update_all(rule: 'improve_type')
  end
end
