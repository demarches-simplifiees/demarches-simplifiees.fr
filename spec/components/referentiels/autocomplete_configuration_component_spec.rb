# frozen_string_literal: true

RSpec.describe Referentiels::AutocompleteConfigurationComponent, type: :component do
  let(:component) { described_class.new(referentiel:, type_de_champ:, procedure:) }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
  let(:referentiel) { create(:api_referentiel, :autocomplete, last_response:) }

  describe 'render' do
    delegate :url_helpers, to: :routes
    delegate :routes, to: :application
    delegate :application, to: Rails

    before do
      render_inline(component)
    end

    context 'when datasource is empty' do
      let(:last_response) { { body: { "key" => "value" } } }
      it 'renders alert error' do
        expect(page).to have_content("Votre source de donnée ne semble pas compatible")
      end
    end

    context 'when datasource count is 1' do
      let(:last_response) { { body: { jsonpath: [{ id: 1, k1: :v1 }] } } }
      it 'renders pre-selected datasource' do
        expect(page).to have_content("Sélectionnez la source de données à exploiter pour l'autocomplete")
        expect(page).to have_selector("input[type=radio][checked]")
      end
    end

    context 'when datasource count more than 1' do
      let(:last_response) do
        {
          body: {
            datasource_1: [{ id: 1, k1: :v1 }],
            datasource_2: [{ id: 1, k2: :v2 }]
          }
        }
      end

      it 'renders selectable datasource' do
        expect(page).to have_content("Sélectionnez la source de données à exploiter pour l'autocomplete")
        expect(page).not_to have_selector("input[type=radio][checked]")
        expect(page).not_to have_selector("input[type=radio][checked]", count: 2)
      end
    end
  end
end
