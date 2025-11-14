# frozen_string_literal: true

class CreateLLMRuleSuggestionItems < ActiveRecord::Migration[7.1]
  def change
    create_table :llm_rule_suggestion_items do |t|
      t.references :llm_rule_suggestion, null: false, foreign_key: true, index: { name: 'index_items_on_llm_rule_suggestion_id' }

      t.string :model

      t.bigint :stable_id
      t.string :op_kind, null: true
      t.jsonb :payload, null: false, default: {}

      t.string :safety, null: false, default: 'safe'
      t.string :verify_status, null: false, default: 'pending'
      t.text :justification
      t.float :confidence
      t.datetime :applied_at

      t.timestamps
    end

    add_index :llm_rule_suggestion_items, :stable_id
    add_index :llm_rule_suggestion_items, :op_kind
    add_index :llm_rule_suggestion_items, :payload, using: :gin
  end
end
