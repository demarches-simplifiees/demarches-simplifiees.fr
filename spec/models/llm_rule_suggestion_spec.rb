# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLMRuleSuggestion, type: :model do
  it 'has associations' do
    expect(subject).to belong_to(:procedure_revision)
    expect(subject).to have_many(:llm_rule_suggestion_items).dependent(:destroy)
  end

  it 'has enums' do
    expect(subject).to define_enum_for(:state).with_values(pending: 'pending', queued: 'queued', running: 'running', completed: 'completed', failed: 'failed', accepted: 'accepted', skipped: 'skipped').backed_by_column_of_type(:string)
    expect(subject).to define_enum_for(:rule).with_values(improve_label: 'improve_label', improve_structure: 'improve_structure', improve_types: 'improve_types', cleaner: 'cleaner').backed_by_column_of_type(:string)
  end

  describe '.next_rule' do
    it 'returns improve_structure after improve_label' do
      expect(LLMRuleSuggestion.next_rule('improve_label')).to eq('improve_structure')
    end

    it 'returns nil after cleaner' do
      expect(LLMRuleSuggestion.next_rule('cleaner')).to be_nil
    end
  end

  describe '.last_rule?' do
    it 'returns false for improve_label' do
      expect(LLMRuleSuggestion.last_rule?('improve_label')).to be false
    end

    it 'returns true for cleaner' do
      expect(LLMRuleSuggestion.last_rule?('cleaner')).to be true
    end
  end

  it 'has validations' do
    expect(subject).to validate_presence_of(:schema_hash)
    expect(subject).to validate_presence_of(:rule)
  end

  describe '.last_for_procedure_revision' do
    let(:procedure) { create(:procedure) }
    let(:procedure_revision) { procedure.draft_revision }

    context 'with suggestions from different procedure revisions' do
      let(:other_procedure) { create(:procedure) }
      let(:other_procedure_revision) { other_procedure.draft_revision }
      let!(:suggestion1) { create(:llm_rule_suggestion, procedure_revision:, state: 'completed') }
      let!(:suggestion2) { create(:llm_rule_suggestion, procedure_revision: other_procedure_revision, state: 'accepted') }

      it 'only returns suggestions for the specified procedure revision' do
        result = procedure_revision.llm_rule_suggestions.last_for_procedure_revision

        expect(result).to eq(suggestion1)
      end
    end
  end

  describe '#llm_rule_suggestion_items_attributes=' do
    let(:procedure) { create(:procedure) }
    let(:llm_rule_suggestion) { create(:llm_rule_suggestion, procedure_revision: procedure.draft_revision) }
    let!(:item1) { create(:llm_rule_suggestion_item, llm_rule_suggestion:) }
    let!(:item2) { create(:llm_rule_suggestion_item, llm_rule_suggestion:) }

    context 'when verify_status is accepted' do
      let(:attributes) do
        {
          '0' => { id: item1.id.to_s, verify_status: 'accepted' },
          '1' => { id: item2.id.to_s, verify_status: 'skipped' },
        }
      end

      it 'sets verify_status to accepted and applied_at to current time for accepted items' do
        expect(llm_rule_suggestion.llm_rule_suggestion_items.count).to eq(2)
        expect(item1.id).to be_present
        expect(item2.id).to be_present

        llm_rule_suggestion.llm_rule_suggestion_items_attributes = attributes

        # item1.reload
        expect(llm_rule_suggestion.llm_rule_suggestion_items.find { |it| it.id == item1.id }.verify_status).to eq('accepted')
        expect(llm_rule_suggestion.llm_rule_suggestion_items.find { |it| it.id == item1.id }.applied_at).to be_present
      end

      it 'sets verify_status to skipped and applied_at to nil for skipped items' do
        llm_rule_suggestion.llm_rule_suggestion_items_attributes = attributes

        expect(llm_rule_suggestion.llm_rule_suggestion_items.find { |it| it.id == item2.id }.verify_status).to eq('skipped')
        expect(llm_rule_suggestion.llm_rule_suggestion_items.find { |it| it.id == item2.id }.applied_at).to be_nil
      end
    end

    context 'when item id does not match' do
      let(:attributes) do
        {
          '0' => { 'id' => '999', 'verify_status' => 'accepted' },
        }
      end

      it 'does not update any items' do
        expect {
          llm_rule_suggestion.llm_rule_suggestion_items_attributes = attributes
        }.not_to change { item1.reload.verify_status }
      end
    end
  end

  describe '#changes_to_apply' do
    let(:procedure) { create(:procedure) }
    let(:llm_rule_suggestion) { create(:llm_rule_suggestion, procedure_revision: procedure.draft_revision) }
    let!(:accepted_item1) { create(:llm_rule_suggestion_item, llm_rule_suggestion:, verify_status: 'accepted', op_kind: 'update') }
    let!(:accepted_item2) { create(:llm_rule_suggestion_item, llm_rule_suggestion:, verify_status: 'accepted', op_kind: 'update') }
    let!(:skipped_item) { create(:llm_rule_suggestion_item, llm_rule_suggestion:, verify_status: 'skipped', op_kind: 'add') }

    it 'groups accepted items by op_kind' do
      result = llm_rule_suggestion.changes_to_apply

      expect(result[:update]).to contain_exactly(accepted_item1, accepted_item2)
      expect(result).not_to have_key(:add)
    end
  end
end
