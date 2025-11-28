# frozen_string_literal: true

RSpec.describe LLM::StepperComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:last_refresh) { Time.zone.local(2025, 10, 13, 14, 40) }
  let(:llm_rule_suggestion) do
    create(:llm_rule_suggestion,
      procedure_revision: procedure.draft_revision,
      rule: rule,
      schema_hash: 'schema-hash',
      state: 'completed').tap { _1.update!(created_at: last_refresh) }
  end
  let(:step_component) { LLM::SuggestionFormComponent.new(llm_rule_suggestion:) }
  subject(:rendered_component) { render_inline(described_class.new(step_component:)) }

  context 'with the label improvement rule' do
    let(:rule) { LLMRuleSuggestion.rules.fetch('improve_label') }
    it 'shows the first step and the correct next step' do
      expect(rendered_component.css('.fr-stepper__state').text).to eq('Étape 1 sur 4')
      expect(rendered_component.css('.fr-stepper__title').text).to include("Amélioration des libellés")
      expect(rendered_component.css('.fr-stepper__details').text).to include("Amélioration de la structure")
      expect(rendered_component).to have_link('Annuler et revenir à l\'écran de gestion', href: Rails.application.routes.url_helpers.admin_procedure_path(procedure))
    end
  end

  context 'with the structure rule' do
    let(:rule) { LLMRuleSuggestion.rules.fetch('improve_structure') }
    it 'marks the second step and shows no further step' do
      expect(rendered_component.css('.fr-stepper__state').text).to eq('Étape 2 sur 4')
      expect(rendered_component.css('.fr-stepper__title').text).to include("Amélioration de la structure")
      expect(rendered_component.css('.fr-stepper__details').text).to include("À venir...")
      expect(rendered_component).to have_link('Annuler et revenir à l\'écran de gestion', href: Rails.application.routes.url_helpers.admin_procedure_path(procedure))
    end
  end
end
