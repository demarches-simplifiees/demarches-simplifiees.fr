RSpec.describe PrefillParams do
  describe "#to_a" do
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :brouillon, procedure: procedure) }

    subject(:prefill_params_array) { described_class.new(dossier, params).to_a }

    context "when the stable ids match the TypeDeChamp of the corresponding procedure" do
      let!(:type_de_champ_1) { create(:type_de_champ_text, procedure: procedure) }
      let(:value_1) { "any value" }
      let(:champ_id_1) { find_champ_by_stable_id(dossier, type_de_champ_1.stable_id).id }

      let!(:type_de_champ_2) { create(:type_de_champ_textarea, procedure: procedure) }
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
      let!(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }

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

    shared_examples "a champ public value that is authorized" do |type_de_champ_name, value|
      context "when the type de champ is authorized (#{type_de_champ_name})" do
        let!(:type_de_champ) { create(type_de_champ_name, procedure: procedure) }
        let(:champ_id) { find_champ_by_stable_id(dossier, type_de_champ.stable_id).id }

        let(:params) { { "champ_#{type_de_champ.to_typed_id}" => value } }

        it "builds an array of hash(id, value) matching the given params" do
          expect(prefill_params_array).to match([{ id: champ_id, value: value }])
        end
      end
    end

    shared_examples "a champ public value that is unauthorized" do |type_de_champ_name, value|
      let!(:type_de_champ) { create(type_de_champ_name, procedure: procedure) }

      let(:params) { { "champ_#{type_de_champ.to_typed_id}" => value } }

      context 'when the type de champ is unauthorized (type_de_champ_name)' do
        it "filters out the param" do
          expect(prefill_params_array).to match([])
        end
      end
    end

    it_behaves_like "a champ public value that is authorized", :type_de_champ_text, "value"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_textarea, "value"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_decimal_number, "3.14"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_integer_number, "42"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_email, "value"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_phone, "value"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_iban, "value"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_yes_no, "true"
    it_behaves_like "a champ public value that is authorized", :type_de_champ_yes_no, "false"

    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_decimal_number, "non decimal string"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_integer_number, "non integer string"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_number, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_communes, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_dossier_link, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_titre_identite, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_checkbox, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_civilite, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_yes_no, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_date, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_datetime, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_drop_down_list, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_multiple_drop_down_list, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_linked_drop_down_list, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_header_section, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_explication, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_piece_justificative, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_repetition, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_cnaf, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_dgfip, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_pole_emploi, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_mesri, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_carte, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_address, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_pays, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_regions, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_departements, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_siret, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_rna, "value"
    it_behaves_like "a champ public value that is unauthorized", :type_de_champ_annuaire_education, "value"
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs_public.joins(:type_de_champ).find_by(types_de_champ: { stable_id: stable_id })
  end
end
