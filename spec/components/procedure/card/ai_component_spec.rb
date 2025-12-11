# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Procedure::Card::AiComponent, type: :component do
  let(:procedure) { create(:procedure, :published) }
  let(:draft_revision) { procedure.draft_revision }

  subject { described_class.new(procedure:) }

  describe '#render?' do
    context 'when LLM feature is enabled' do
      before { Flipper.enable_actor(:llm_nightly_improve_procedure, procedure) }
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end

    context 'when LLM feature is disabled' do
      it 'returns false' do
        expect(subject.render?).to be false
      end
    end
  end

  describe 'rendered component' do
    before { Flipper.enable_actor(:llm_nightly_improve_procedure, procedure) }

    context 'avec suggestions' do
      let(:schema_hash) { Digest::SHA256.hexdigest(draft_revision.schema_to_llm.to_json) }
      before do
        create(:llm_rule_suggestion,
               procedure_revision: draft_revision,
               schema_hash:,
               state:,
               rule:)
      end

      context 'when last rule is not started' do
        let(:rule) { 'improve_label' }
        let(:state) { :accepted }

        it do
          render_inline(subject)
          expect(page).to have_css('.fr-badge--warning', text: 'À faire')
        end
      end

      context 'when last rule is not finished' do
        let(:rule) { 'improve_structure' }
        let(:state) { :completed }

        it do
          render_inline(subject)
          expect(page).to have_css('.fr-badge--warning', text: 'À faire')
        end
      end

      context 'when last rule is done' do
        let(:rule) { 'cleaner' }
        let(:state) { :accepted }

        it do
          render_inline(subject)
          expect(page).to have_css('.fr-badge--success', text: 'Amélioré')
        end
      end

      context 'when schema changed' do
        let(:rule) { 'improve_structure' }
        let(:state) { :accepted }
        let(:schema_hash) { "something-else" }

        it do
          render_inline(subject)
          expect(page).to have_css('.fr-badge--warning', text: 'À faire')
        end
      end
    end

    context 'sans amélioration' do
      it 'affiche le badge À faire' do
        render_inline(subject)
        expect(page).to have_css('.fr-badge--warning', text: 'À faire')
      end
    end
  end
end
