# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLMRuleSuggestion, type: :model do
  it 'has associations' do
    expect(subject).to belong_to(:procedure_revision)
    expect(subject).to have_many(:llm_rule_suggestion_items).dependent(:destroy)
  end

  it 'has enums' do
    expect(subject).to define_enum_for(:state).with_values(pending: 'pending', queued: 'queued', running: 'running', completed: 'completed', failed: 'failed', accepted: 'accepted', skipped: 'skipped').backed_by_column_of_type(:string)
    expect(subject).to define_enum_for(:rule).with_values(improve_label: 'improve_label').backed_by_column_of_type(:string)
  end

  it 'has validations' do
    expect(subject).to validate_presence_of(:schema_hash)
    expect(subject).to validate_presence_of(:rule)
  end
end
