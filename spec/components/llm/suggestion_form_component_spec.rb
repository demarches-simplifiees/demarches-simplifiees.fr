# frozen_string_literal: true

RSpec.describe LLM::SuggestionFormComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :text, libelle: 'Nom' }]) }
  let(:rule) { LLMRuleSuggestion.rules.fetch('improve_label') }
  let(:schema_hash) { 'schema-hash' }
  let(:llm_rule_suggestion) { create(:llm_rule_suggestion, procedure_revision: procedure.draft_revision, rule:, schema_hash:, state:) }

  subject { render_inline(described_class.new(llm_rule_suggestion: llm_rule_suggestion)) }

  describe 'rendering' do
    context 'when state is queued' do
      let(:state) { 'queued' }

      it "afficher en attente (delai d'attente dans la queue)" do
        expect(subject).to have_content("Recherche en cours")
        expect(subject).not_to have_css("button[value='Lancer la recherche de suggestions']")
      end
    end
    context 'when state is running' do
      let(:state) { 'running' }

      it "afficher en attente (delai de ± 40 secs?)" do
        expect(subject).to have_content("Recherche en cours")
        expect(subject).not_to have_css("button[value='Lancer la recherche de suggestions']")
      end
    end

    context 'when state is completed' do
      let(:state) { 'completed' }
      before do
        revision_coordinate = procedure.draft_revision.revision_types_de_champ_public.first

        create(:llm_rule_suggestion_item,
          llm_rule_suggestion:,
          stable_id: revision_coordinate.stable_id,
          payload: { 'stable_id' => revision_coordinate.stable_id, 'libelle' => 'Nom simplifié' })
      end

      it 'shows the configured title' do
        expect(subject.css('h2').text).to include(LLM::ImproveLabelItemComponent.step_title)
        expect(subject.text).to include(LLM::ImproveLabelItemComponent.step_summary)
        expect(subject).not_to have_css("button[value='Lancer la recherche de suggestions']")
      end

      it 'disables submit button when no suggestions are accepted' do
        expect(subject).to have_css("input[type='submit'][disabled]")
      end

      context 'when at least one suggestion is accepted' do
        before do
          llm_rule_suggestion.llm_rule_suggestion_items.first.update(verify_status: 'accepted')
        end

        it 'enables submit button' do
          expect(subject).not_to have_css("input[type='submit'][disabled]")
        end
      end
    end
    context 'when state is failed' do
      let(:state) { 'failed' }

      it "echouer, afficher l'erreur et pouvoir relancer" do
        expect(subject).to have_content("La génération des suggestions a echoué, veuillez ré-essayer")
        expect(subject).to have_button("Régénérer les suggestions")
      end
    end
    context 'when state is accepted' do
      let(:state) { 'accepted' }

      it "si accepté, dire que ca a ete fait mais on peut relancer?" do
        expect(subject).to have_content("Vous avez déjà accepté des suggestions, vous pouvez les regénérer")
        expect(subject).to have_button("Régénérer les suggestions")
      end
    end
    context 'when state is skipped' do
      let(:state) { 'skipped' }

      it "si skipé, dire que ca a ete fait mais on peut relancer?" do
        expect(subject).to have_content("Vous avez déjà ignorer des suggestions, souhaitez-vous en regénérer ?")
        expect(subject).to have_button("Régénérer les suggestions")
      end
    end
  end
end
