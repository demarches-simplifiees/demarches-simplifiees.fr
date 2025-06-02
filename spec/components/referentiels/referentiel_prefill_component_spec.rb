# frozen_string_literal: true

RSpec.describe Referentiels::ReferentielPrefillComponent, type: :component do
  let(:component) { described_class.new(referentiel:, type_de_champ:, procedure:) }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
  let(:referentiel) { create(:api_referentiel, :configured) }

  before { Flipper.enable_actor(:referentiel_type_de_champ, procedure) }
  subject { render_inline(component) }
  describe 'render' do
    context 'when mapping is blank' do
      it { expect(subject.to_html).to be_empty }
    end

    context 'when mapping is present' do
      let(:referentiel_mapping) do
        {
          "$.jsonpath" => {
            "prefill" => '1',
            'type' => Referentiels::MappingFormComponent::TYPES.values.first
          }
        }
      end

      before { type_de_champ.update(referentiel_mapping:) }

      it 'renders the table headers' do
        expect(subject).to have_selector('th', text: 'Propriété')
        expect(subject).to have_selector('th', text: 'Exemple de donnée')
        expect(subject).to have_selector('th', text: 'Type de Donnée')
        expect(subject).to have_selector('th', text: 'Champ du formulaire usager à préremplir')
      end
    end
  end

  describe 'selectable source_tdcs' do
    let(:prefill_stable_id) { nil }

    let(:referentiel_mapping) do
      {
        "$.jsonpath" => {
          "prefill" => '1',
          'type' => Referentiels::MappingFormComponent::TYPES.values.first,
          'prefill_stable_id' => prefill_stable_id
        }
      }
    end

    let(:types_de_champ_public) do
      [
        { type: :referentiel, referentiel: },
        { stable_id: prefill_stable_id, type: :text, libelle: 'text' },
        { stable_id: 2, type: :decimal_number, libelle: 'decimal' }
      ]
    end

    before { type_de_champ.update(referentiel_mapping:) }

    context 'when prefill_stable_id is not selected' do
      it 'shows all selectable source_tdcs except current' do
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', options: ['text', 'decimal'])
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', selected: [])
      end
    end

    context 'when prefill_stable_id is selected' do
      let(:prefill_stable_id) { 1 }
      it 'shows the selected prefill_stable_id' do
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', selected: ['text'])
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', selected: ['text'])
      end
    end
  end
end
