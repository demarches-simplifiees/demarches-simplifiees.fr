# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Procedure::Card::AiComponent, type: :component do
  let(:procedure) { create(:procedure, :published) }
  let(:draft_revision) { procedure.draft_revision }

  subject { described_class.new(procedure:) }

  describe '#rule' do
    context 'when there is a last LLM rule suggestion' do
      let!(:suggestion) { create(:llm_rule_suggestion, procedure_revision: draft_revision, rule: 'improve_label') }

      it 'returns the rule of the last suggestion' do
        expect(subject.rule).to eq('improve_label')
      end
    end

    context 'when there is no LLM rule suggestion' do
      it 'returns the default rule' do
        expect(subject.rule).to eq('improve_label')
      end
    end
  end

  describe '#render?' do
    context 'when LLM feature is enabled' do
      before { Flipper.enable_actor(:llm_nightly_improve_procedure, procedure) }

      it 'returns true' do
        expect(subject.render?).to be true
      end
    end

    context 'when LLM feature is disabled' do
      before { Flipper.disable_actor(:llm_nightly_improve_procedure, procedure) }

      it 'returns false' do
        expect(subject.render?).to be false
      end
    end
  end

  describe '#last_llm_rule_suggestion' do
    let!(:accepted_suggestion) { create(:llm_rule_suggestion, procedure_revision: draft_revision, rule: 'improve_label', state: 'accepted') }
    let!(:completed_suggestion) { create(:llm_rule_suggestion, procedure_revision: draft_revision, rule: 'improve_label', state: 'completed') }

    it 'returns the last suggestion according to the priority order' do
      # Accepted should come first
      expect(subject.send(:last_llm_rule_suggestion)).to eq(accepted_suggestion)
    end
  end
end
