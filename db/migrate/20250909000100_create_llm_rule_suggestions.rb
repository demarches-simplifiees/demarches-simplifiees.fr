# frozen_string_literal: true

class CreateLLMRuleSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :llm_rule_suggestions do |t|
      t.references :procedure_revision, null: false, foreign_key: { to_table: :procedure_revisions }
      t.string :schema_hash, null: false
      t.string :state, null: false, default: 'queued'
      t.jsonb :token_usage
      t.string :rule, null: false

      t.text :error
      t.timestamps
    end

    add_index :llm_rule_suggestions, [:procedure_revision_id, :schema_hash], name: 'index_llm_rule_suggestions_on_revision_and_hash'
  end
end
