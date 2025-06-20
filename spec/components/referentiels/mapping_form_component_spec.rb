# frozen_string_literal: true

RSpec.describe Referentiels::MappingFormComponent, type: :component do
  let(:component) { described_class.new(referentiel:, type_de_champ:, procedure:) }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
  let(:referentiel) { create(:api_referentiel, :configured) }

  describe 'render' do
    delegate :url_helpers, to: :routes
    delegate :routes, to: :application
    delegate :application, to: Rails

    before do
      Flipper.enable_actor(:referentiel_type_de_champ, procedure)
      render_inline(component)
    end

    context 'when referentiel is not ready' do
      it 'render error' do
        expect(page).to have_text(component.error_title)
        expect(page).to have_selector("button.fr-btn[disabled]")
      end
    end

    context 'when referentiel is properly configured' do
      let(:referentiel) { create(:api_referentiel, :with_last_response, :configured) }

      it 'table' do
        # thead
        expect(page).to have_selector("th", text: "Propriété")
        expect(page).to have_selector("th", text: "Exemple de donnée")
        expect(page).to have_selector("th", text: "Type de donnée")
        expect(page).to have_selector("th", text: "Utiliser la donnée\n\npour préremplir\n\nun champ du\n\nformulaire")
        expect(page).to have_selector("th", text: "Libellé de la donnée récupérée\n\n(pour afficher à l'usager et/ou l'instructeur)")

        # tbody
        jsonpaths = page.all("tr td:nth-child(1)").map(&:text).map(&:strip)
        ["$.point.type", "$.point.coordinates", "$.shape.type"].each do |sample|
          expect(jsonpaths).to include("Utiliser #{sample} pour préremplir le formulaire\n#{sample}")
        end
        values = page.all("tr td:nth-child(2)").map(&:text).map(&:strip)
        ["Point", "[-0.570505392116188, 44.841034137099996]", "MultiPolygon"].each do |sample|
          expect(values).to include(sample)
        end

        # navigation
        expect(page).to have_selector("form[action=\"#{url_helpers.update_mapping_type_de_champ_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel)}\"]")
        expect(page).to have_selector('input[type=submit][value="Étape suivante"]')
        expect(page).to have_link("Étape précédente", href: url_helpers.edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id))
        expect(page).to have_selector("input[type=submit]")
      end
    end
  end

  describe "value_to_type" do
    def convert_json_value_to_type(value:)
      component.send(:value_to_type, JSON.parse({ value: }.to_json)["value"])
    end

    it "simple json value to type symbol" do
      expect(convert_json_value_to_type(value: 1)).to eq(:integer_number)
      expect(convert_json_value_to_type(value: 1.1)).to eq(:decimal_number)
      expect(convert_json_value_to_type(value: true)).to eq(:boolean)
      expect(convert_json_value_to_type(value: false)).to eq(:boolean)
      expect(convert_json_value_to_type(value: "hello")).to eq(:string)
    end

    it "detects ISO8601 date as :date" do
      expect(convert_json_value_to_type(value: "2024-06-14")).to eq(:date)
    end

    it "does not detect invalid date as :date" do
      expect(convert_json_value_to_type(value: "2024-13-14")).to eq(:string)
      expect(convert_json_value_to_type(value: "2024-06-31")).to eq(:string)
    end

    it "does not detect embedded date in string as :date" do
      expect(convert_json_value_to_type(value: "RDV le 2024-06-14 à 10h")).to eq(:date)
    end

    it "detects ISO8601 datetime as :datetime" do
      expect(convert_json_value_to_type(value: "2024-06-14T12:34")).to eq(:datetime)
      expect(convert_json_value_to_type(value: "2024-06-14T12:34:56+02:00")).to eq(:datetime)
    end

    it "does not detect invalid date as :datetime" do
      expect(convert_json_value_to_type(value: "2024-13-14T25:34")).to eq(:string)
      expect(convert_json_value_to_type(value: "2024-06-31T25:34")).to eq(:string)
    end

    it "detects array of simple values as :array" do
      expect(convert_json_value_to_type(value: ["option1", "option2"])).to eq(:array)
      expect(convert_json_value_to_type(value: [1, 2, 3])).to eq(:array)
      expect(convert_json_value_to_type(value: [1.1, 2.2])).to eq(:array)
    end

    it "does not detect array of objects as :string" do
      expect(convert_json_value_to_type(value: [{ a: 1 }, { b: 2 }])).to eq(:string)
      expect(convert_json_value_to_type(value: [[1, 2], [3, 4]])).to eq(:string)
    end
  end
end
