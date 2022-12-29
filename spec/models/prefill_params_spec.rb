RSpec.describe PrefillParams do
  describe "#to_a" do
    let(:procedure) { create(:procedure, :published, types_de_champ_public:, types_de_champ_private:) }
    let(:dossier) { create(:dossier, :brouillon, procedure: procedure) }
    let(:types_de_champ_public) { [] }
    let(:types_de_champ_private) { [] }

    subject(:prefill_params_array) { described_class.new(dossier, params).to_a }

    context "when the stable ids match the TypeDeChamp of the corresponding procedure" do
      let(:types_de_champ_public) { [{ type: :text }, { type: :textarea }] }
      let(:type_de_champ_1) { procedure.published_revision.types_de_champ_public.first }
      let(:value_1) { "any value" }
      let(:champ_id_1) { find_champ_by_stable_id(dossier, type_de_champ_1.stable_id).id }

      let(:type_de_champ_2) { procedure.published_revision.types_de_champ_public.second }
      let(:value_2) { "another value" }
      let(:champ_id_2) { find_champ_by_stable_id(dossier, type_de_champ_2.stable_id).id }

      let(:params) {
        {
          "champ_#{type_de_champ_1.to_typed_id}" => value_1,
          "champ_#{type_de_champ_2.to_typed_id}" => value_2
        }
      }

      it "builds an array of hash(id, value) matching all the given params" do
        expect(prefill_params_array).to match([
          { id: champ_id_1, value: value_1 },
          { id: champ_id_2, value: value_2 }
        ])
      end
    end

    context "when the typed id is not prefixed by 'champ_'" do
      let(:type_de_champ) { procedure.published_revision.types_de_champ_public.first }
      let(:types_de_champ_public) { [{ type: :text }] }

      let(:params) { { type_de_champ.to_typed_id => "value" } }

      it "filters out the champ" do
        expect(prefill_params_array).to match([])
      end
    end

    context "when the typed id is unknown" do
      let(:params) { { "champ_jane_doe" => "value" } }

      it "filters out the unknown params" do
        expect(prefill_params_array).to match([])
      end
    end

    context 'when there is no Champ that matches the TypeDeChamp with the given stable id' do
      let!(:type_de_champ) { create(:type_de_champ_text) } # goes to another procedure

      let(:params) { { "champ_#{type_de_champ.to_typed_id}" => "value" } }

      it "filters out the param" do
        expect(prefill_params_array).to match([])
      end
    end

    shared_examples "a champ public value that is authorized" do |type_de_champ_type, value|
      context "when the type de champ is authorized (#{type_de_champ_type})" do
        let(:types_de_champ_public) { [{ type: type_de_champ_type }] }
        let(:type_de_champ) { procedure.published_revision.types_de_champ_public.first }
        let(:champ_id) { find_champ_by_stable_id(dossier, type_de_champ.stable_id).id }

        let(:params) { { "champ_#{type_de_champ.to_typed_id}" => value } }

        it "builds an array of hash(id, value) matching the given params" do
          expect(prefill_params_array).to match([{ id: champ_id, value: value }])
        end
      end
    end

    shared_examples "a champ private value that is authorized" do |type_de_champ_type, value|
      context "when the type de champ is authorized (#{type_de_champ_type})" do
        let(:types_de_champ_private) { [{ type: type_de_champ_type }] }
        let(:type_de_champ) { procedure.published_revision.types_de_champ_private.first }
        let(:champ_id) { find_champ_by_stable_id(dossier, type_de_champ.stable_id).id }

        let(:params) { { "champ_#{type_de_champ.to_typed_id}" => value } }

        it "builds an array of hash(id, value) matching the given params" do
          expect(prefill_params_array).to match([{ id: champ_id, value: value }])
        end
      end
    end

    shared_examples "a champ public value that is unauthorized" do |type_de_champ_type, value|
      let(:types_de_champ_public) { [{ type: type_de_champ_type }] }
      let(:type_de_champ) { procedure.published_revision.types_de_champ_public.first }

      let(:params) { { "champ_#{type_de_champ.to_typed_id}" => value } }

      context "when the type de champ is unauthorized (#{type_de_champ_type})" do
        it "filters out the param" do
          expect(prefill_params_array).to match([])
        end
      end
    end

    it_behaves_like "a champ public value that is authorized", :text, "value"
    it_behaves_like "a champ public value that is authorized", :textarea, "value"
    it_behaves_like "a champ public value that is authorized", :decimal_number, "3.14"
    it_behaves_like "a champ public value that is authorized", :integer_number, "42"
    it_behaves_like "a champ public value that is authorized", :email, "value"
    it_behaves_like "a champ public value that is authorized", :phone, "value"
    it_behaves_like "a champ public value that is authorized", :iban, "value"
    it_behaves_like "a champ public value that is authorized", :civilite, "M."
    it_behaves_like "a champ public value that is authorized", :pays, "FR"

    it_behaves_like "a champ private value that is authorized", :text, "value"
    it_behaves_like "a champ private value that is authorized", :textarea, "value"
    it_behaves_like "a champ private value that is authorized", :decimal_number, "3.14"
    it_behaves_like "a champ private value that is authorized", :integer_number, "42"
    it_behaves_like "a champ private value that is authorized", :email, "value"
    it_behaves_like "a champ private value that is authorized", :phone, "value"
    it_behaves_like "a champ private value that is authorized", :iban, "value"
    it_behaves_like "a champ private value that is authorized", :civilite, "M."
    it_behaves_like "a champ private value that is authorized", :pays, "FR"

    it_behaves_like "a champ public value that is unauthorized", :decimal_number, "non decimal string"
    it_behaves_like "a champ public value that is unauthorized", :integer_number, "non integer string"
    it_behaves_like "a champ public value that is unauthorized", :number, "value"
    it_behaves_like "a champ public value that is unauthorized", :communes, "value"
    it_behaves_like "a champ public value that is unauthorized", :dossier_link, "value"
    it_behaves_like "a champ public value that is unauthorized", :titre_identite, "value"
    it_behaves_like "a champ public value that is unauthorized", :checkbox, "value"
    it_behaves_like "a champ public value that is unauthorized", :civilite, "value"
    it_behaves_like "a champ public value that is unauthorized", :yes_no, "value"
    it_behaves_like "a champ public value that is unauthorized", :date, "value"
    it_behaves_like "a champ public value that is unauthorized", :datetime, "value"
    it_behaves_like "a champ public value that is unauthorized", :drop_down_list, "value"
    it_behaves_like "a champ public value that is unauthorized", :multiple_drop_down_list, "value"
    it_behaves_like "a champ public value that is unauthorized", :linked_drop_down_list, "value"
    it_behaves_like "a champ public value that is unauthorized", :header_section, "value"
    it_behaves_like "a champ public value that is unauthorized", :explication, "value"
    it_behaves_like "a champ public value that is unauthorized", :piece_justificative, "value"
    it_behaves_like "a champ public value that is unauthorized", :repetition, "value"
    it_behaves_like "a champ public value that is unauthorized", :cnaf, "value"
    it_behaves_like "a champ public value that is unauthorized", :dgfip, "value"
    it_behaves_like "a champ public value that is unauthorized", :pole_emploi, "value"
    it_behaves_like "a champ public value that is unauthorized", :mesri, "value"
    it_behaves_like "a champ public value that is unauthorized", :carte, "value"
    it_behaves_like "a champ public value that is unauthorized", :address, "value"
    it_behaves_like "a champ public value that is unauthorized", :pays, "value"
    it_behaves_like "a champ public value that is unauthorized", :regions, "value"
    it_behaves_like "a champ public value that is unauthorized", :departements, "value"
    it_behaves_like "a champ public value that is unauthorized", :siret, "value"
    it_behaves_like "a champ public value that is unauthorized", :rna, "value"
    it_behaves_like "a champ public value that is unauthorized", :annuaire_education, "value"
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs.joins(:type_de_champ).find_by(types_de_champ: { stable_id: stable_id })
  end
end
