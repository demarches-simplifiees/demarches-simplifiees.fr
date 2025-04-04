# frozen_string_literal: true

RSpec.describe Referentiels::MappingFormComponent, type: :component do
  let(:component) { described_class.new(referentiel:, type_de_champ:, procedure:) }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
  let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
  let(:referentiel) { create(:api_referentiel, :configured, url: whitelist.first) }
  let(:whitelist) { %w[https://rnb-api.beta.gouv.fr] }
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('API_WHITELIST', '').and_return(whitelist.join(','))
  end
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
      let(:referentiel) { create(:api_referentiel, :with_last_response, :configured, url: whitelist.first) }

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
    def convert_json_value_to_human(value:) = component.send(:value_to_type, JSON.parse({ value: }.to_json)["value"])

    it "json value to human" do
      expect(convert_json_value_to_human(value: 1)).to eq("Nombre Entier")
      expect(convert_json_value_to_human(value: 1.1)).to eq("Nombre à virgule")
      expect(convert_json_value_to_human(value: true)).to eq("Booléen")
      expect(convert_json_value_to_human(value: false)).to eq("Booléen")
      expect(convert_json_value_to_human(value: "hello")).to eq("Chaine de caractère")
      expect(convert_json_value_to_human(value: [1, 2])).to eq("Chaine de caractère")
    end
  end

  describe 'hash_to_jsonpath' do
    def hash_to_jsonpath(hash) = component.send(:hash_to_jsonpath, hash)

    it 'jsonpathify simple hash' do
      expect(hash_to_jsonpath({ "key" => "value" })).to eq({
        "$.key" => "value"
      })
    end
    it 'jsonpathify nested hash' do
      expect(hash_to_jsonpath({ "key" => { "nested" => "value" } })).to eq({
        "$.key.nested" => "value"
      })
    end
    it 'jsonpathify nested hash' do
      expect(hash_to_jsonpath({ data: [{ "key" => "value" }] })).to eq({
        "$.data[0].key" => "value"
      })
    end
    it 'jsonpathify real response' do
      rnb_json = JSON.parse(File.read('spec/fixtures/files/api_referentiel_rnb.json'))
      expect(hash_to_jsonpath(rnb_json).keys).to match_array([
        "$.point.type",
        "$.point.coordinates",
        "$.shape.type",
        "$.shape.coordinates",
        "$.rnb_id",
        "$.status",
        "$.ext_ids[0].id",
        "$.ext_ids[0].source",
        "$.ext_ids[0].created_at",
        "$.ext_ids[0].source_version",
        "$.addresses[0].id",
        "$.addresses[0].source",
        "$.addresses[0].street",
        "$.addresses[0].city_name",
        "$.addresses[0].street_rep",
        "$.addresses[0].city_zipcode",
        "$.addresses[0].street_number",
        "$.addresses[0].city_insee_code",
        "$.is_active"
      ])
    end
  end
end
