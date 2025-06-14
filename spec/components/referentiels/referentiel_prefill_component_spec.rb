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
    before { type_de_champ.update(referentiel_mapping:) }
    let(:prefill_stable_id) { nil }

    let(:referentiel_mapping) do
      {
        "$.jsonpath" => {
          "prefill" => '1',
          'type' => referentiel_mapping_type,
          'prefill_stable_id' => prefill_stable_id
        }
      }
    end

    context 'with mapping type "Chaine de caractère"' do
      let(:referentiel_mapping_type) { Referentiels::MappingFormComponent::TYPES[String] }
      let(:types_de_champ_public) do
        [
          { type: :referentiel, referentiel: }, # exclu (champ courant)
          { stable_id: 1, type: :text, libelle: 'text' },
          { stable_id: 2, type: :textarea, libelle: 'textarea' },
          { stable_id: 6, type: :yes_no, libelle: 'yes_no' } # exclu (type non compatible)
        ]
      end

      context 'when not selected' do
        it 'shows only text and textarea' do
          expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', options: ['text', 'textarea'])
        end
      end
      context 'when prefill_stable_id is selected' do
        let(:prefill_stable_id) { 1 }
        it 'shows the selected prefill_stable_id' do
          expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', selected: ['text'])
        end
      end
    end

    context 'with mapping type "Nombre à virgule"' do
      let(:referentiel_mapping_type) { Referentiels::MappingFormComponent::TYPES[Float] }
      let(:types_de_champ_public) do
        [
          { type: :referentiel, referentiel: }, # exclu (champ courant)
          { stable_id: 1, type: :text, libelle: 'text' }, # exclu (type non compatible)
          { stable_id: 3, type: :decimal_number, libelle: 'decimal' }
        ]
      end
      it 'shows only decimal_number' do
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', options: ['decimal'])
      end
    end

    context 'with mapping type "Nombre Entier"' do
      let(:referentiel_mapping_type) { Referentiels::MappingFormComponent::TYPES[Integer] }
      let(:types_de_champ_public) do
        [
          { type: :referentiel, referentiel: }, # exclu (champ courant)
          { stable_id: 3, type: :decimal_number, libelle: 'decimal' }, # exclu (type non compatible)
          { stable_id: 4, type: :integer_number, libelle: 'integer' }
        ]
      end
      it 'shows only integer_number' do
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', options: ['integer'])
      end
    end

    context 'with mapping type "Booléen"' do
      let(:referentiel_mapping_type) { Referentiels::MappingFormComponent::TYPES[TrueClass] }
      let(:types_de_champ_public) do
        [
          { type: :referentiel, referentiel: }, # exclu (champ courant)
          { stable_id: 1, type: :text, libelle: 'text' }, # exclu (type non compatible)
          { stable_id: 5, type: :checkbox, libelle: 'checkbox' },
          { stable_id: 6, type: :yes_no, libelle: 'yes_no' }
        ]
      end
      it 'shows only checkbox and yes_no' do
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', options: ['checkbox', 'yes_no'])
      end
    end

    context 'with mapping type "Date"' do
      let(:referentiel_mapping_type) { "Date" }
      let(:types_de_champ_public) do
        [
          { type: :referentiel, referentiel: }, # exclu (champ courant)
          { stable_id: 7, type: :date, libelle: 'date' },
          { stable_id: 8, type: :text, libelle: 'text' } # exclu (type non compatible)
        ]
      end
      it 'shows only date' do
        expect(subject).to have_select('type_de_champ[referentiel_mapping][$.jsonpath][prefill_stable_id]', options: ['date'])
      end
    end
  end
end
