# frozen_string_literal: true

require 'digest'

describe Administrateurs::TypesDeChampController, type: :controller do
  let(:procedure) do
    create(:procedure,
           types_de_champ_public: [
             { type: :integer_number, libelle: 'l1' },
             { type: :integer_number, libelle: 'l2' },
             { type: :drop_down_list, libelle: 'l3' },
           ],
           types_de_champ_private: [
             { type: :yes_no, libelle: 'bon dossier', private: true },
           ])
  end

  def first_coordinate = procedure.draft_revision.revision_types_de_champ_public.first
  def second_coordinate = procedure.draft_revision.reload.revision_types_de_champ_public.second
  def third_coordinate = procedure.draft_revision.revision_types_de_champ_public.third

  def extract_libelle(champ_component) = [champ_component.coordinate.libelle, champ_component.upper_coordinates.map(&:libelle)]

  def morpheds
    assigns(:morphed)
      .map { |component| extract_libelle(component) }.to_a
  end

  before { sign_in(procedure.administrateurs.first.user) }

  describe '#create' do
    let(:params) { default_params }

    let(:default_params) do
      {
        procedure_id: procedure.id,
        type_de_champ: {
          type_champ: type_champ,
          libelle: 'l1.5',
          after_stable_id: first_coordinate.stable_id,
        },
      }
    end

    subject { post :create, params: params, format: :turbo_stream }

    context "create type_de_champ text" do
      let(:type_champ) { TypeDeChamp.type_champs.fetch(:text) }

      # l1, l2, l3 => l1, l1.5, l2, l3
      # created: (l1.5, [l1]), morphed: (l2, [l1, l1.5]), (l3, [l1, l1.5, l2])
      it do
        is_expected.to have_http_status(:ok)
        expect(flash.alert).to eq(nil)
        expect(assigns(:coordinate)).to eq(second_coordinate)
        expect(extract_libelle(assigns(:created))).to eq(['l1.5', ['l1']])
        expect(morpheds).to eq([['l2', ['l1', 'l1.5']], ['l3', ['l1', 'l1.5', 'l2']]])
      end
    end

    context "validate" do
      let(:type_champ) { TypeDeChamp.type_champs.fetch(:text) }
      let(:params) { default_params.deep_merge(type_de_champ: { type_champ: nil }) }

      it do
        is_expected.to have_http_status(:ok)
        expect(assigns(:coordinate)).to be_nil
        expect(flash.alert).to eq(["Le champ « Type champ » doit être rempli"])
      end
    end
  end

  describe '#update' do
    let(:params) { default_params }
    let(:default_params) do
      {
        procedure_id: procedure.id,
        stable_id: second_coordinate.stable_id,
        type_de_champ: {
          libelle: 'updated',
        },
      }
    end

    subject { post :update, params: params, format: :turbo_stream }

    # l1, l2, l3 => l1, updated, l3
    # morphed: (updated, [l1]), (l3, [l1, updated])
    it do
      is_expected.to have_http_status(:ok)
      expect(flash.alert).to eq(nil)
      expect(second_coordinate.libelle).to eq('updated')

      expect(assigns(:coordinate)).to eq(second_coordinate)
      expect(morpheds).to eq([['updated', ['l1']], ['l3', ['l1', 'updated']]])
    end

    context "validate" do
      let(:params) { default_params.deep_merge(type_de_champ: { libelle: '' }) }

      it do
        is_expected.to have_http_status(:ok)
        expect(assigns(:coordinate)).to eq(second_coordinate)
        expect(flash.alert).to be_nil
      end
    end

    context 'rejected if type changed and routing involved' do
      let(:params) do
        default_params.deep_merge(type_de_champ: { type_champ: 'text', stable_id: third_coordinate.stable_id })
      end

      before do
        allow_any_instance_of(ProcedureRevisionTypeDeChamp).to receive(:used_by_routing_rules?).and_return(true)
      end

      it do
        is_expected.to have_http_status(:ok)
        expect(flash.alert).to include("utilisé pour le routage")
      end
    end

    context 'with a dropdown list with a referentiel' do
      let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel.csv', 'text/csv') }
      let(:drop_down_list_type_de_champ) do
        procedure.draft_revision.types_de_champ_public.third
      end

      let(:params) do
        {
          procedure_id: procedure.id,
          stable_id: third_coordinate.stable_id,
          referentiel_file:,
          name: referentiel_file.original_filename,
          type_de_champ: {
            libelle: 'updated',
          },
        }
      end

      context 'working case with multi column file' do
        it 'creates a valid referentiel' do
          expect { subject }.to change(Referentiel, :count).by(1).and change(ReferentielItem, :count).by(3)
          expect(drop_down_list_type_de_champ.reload.referentiel).to eq Referentiel.last
          expect(Referentiel.last.types_de_champ).to eq [drop_down_list_type_de_champ]
          expect(Referentiel.last.name).to eq referentiel_file.original_filename
          expect(Referentiel.last.type).to eq 'Referentiels::CsvReferentiel'
          expect(ReferentielItem.first.data).to eq({ "row" => { "calorie_kcal" => "145", "dessert" => "Éclair au café", "poids_g" => "60" } })
          expect(ReferentielItem.first.referentiel_id).to eq(Referentiel.last.id)
        end
      end

      context 'working case with uniq column file' do
        let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-one-column-referentiel.csv', 'text/csv') }

        it 'creates a valid referentiel' do
          expect { subject }.to change(Referentiel, :count).by(1).and change(ReferentielItem, :count).by(3)
          expect(ReferentielItem.first.data).to eq({ "row" => { "dessert" => "Éclair au café" } })
        end
      end

      context 'when the csv file length is more than 10 mo' do
        let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel.csv', 'text/csv') }

        before do
          allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(11.megabytes)
          subject
        end

        it 'verifies the file size limitation' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : le poids du fichier est supérieur à 1 Mo")
        end
      end

      context 'when the file content type is not accepted' do
        let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/french-flag.gif', 'image/gif') }

        before { subject }

        it 'checks file format acceptance' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : veuillez importer un fichier CSV")
        end
      end

      context 'when the csv file has a bom' do
        let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel-with-bom.csv', 'text/csv') }

        it 'creates a valid referentiel' do
          expect { subject }.to change(Referentiel, :count).by(1).and change(ReferentielItem, :count).by(13)
          expect(ReferentielItem.first.data).to eq({ "row" => { "description" => "Direction des Affaires financières et sociales", "flex_value" => "AFS" } })
        end
      end

      context 'when the csv file has no separators' do
        let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel-without-separators.csv', 'text/csv') }
        before { subject }

        it 'catches smarter csv error' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : le fichier est vide ou mal interprété")
        end
      end

      context 'when the csv file is iso-8859 format, with CRLF line terminators and special characters (even in header)' do
        let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel-iso-8859-crlf-special-characters.csv', 'text/csv') }
        it 'works' do
          expect { subject }.to change(Referentiel, :count).by(1).and change(ReferentielItem, :count).by(2)
          expect(ReferentielItem.first.data).to eq({ "row" => { "adresse" => "115, Boulevard Exelmans, Paris, 75016", "email" => "moha.ali@diplomatie.gouv.fr", "nom" => "Mohamed Ali", "numero" => "UK +447 864 743 320" } })
          expect(Referentiel.first.headers).to eq(["adresse", "nom", "numéro", "email"])
        end
      end
    end

    context 'with a multiple dropdown list with a referentiel' do
      let(:procedure) do
        create(:procedure,
               types_de_champ_public: [
                 { type: :multiple_drop_down_list, libelle: 'l1' },
               ])
      end
      let(:referentiel_file) { fixture_file_upload('spec/fixtures/files/modele-import-referentiel.csv', 'text/csv') }
      let(:multiple_drop_down_list_type_de_champ) do
        procedure.draft_revision.types_de_champ_public.first
      end
      let(:coordinate) { procedure.draft_revision.revision_types_de_champ_public.first }

      let(:params) do
        {
          procedure_id: procedure.id,
          stable_id: coordinate.stable_id,
          referentiel_file:,
          name: referentiel_file.original_filename,
          type_de_champ: {
            libelle: 'updated',
          },
        }
      end

      context 'working case with multi column file' do
        it 'creates a valid referentiel' do
          expect { subject }.to change(Referentiel, :count).by(1).and change(ReferentielItem, :count).by(3)
          expect(multiple_drop_down_list_type_de_champ.reload.referentiel).to eq Referentiel.last
          expect(Referentiel.last.types_de_champ).to eq [multiple_drop_down_list_type_de_champ]
          expect(Referentiel.last.name).to eq referentiel_file.original_filename
          expect(Referentiel.last.type).to eq 'Referentiels::CsvReferentiel'
          expect(ReferentielItem.first.data).to eq({ "row" => { "calorie_kcal" => "145", "dessert" => "Éclair au café", "poids_g" => "60" } })
          expect(ReferentielItem.first.referentiel_id).to eq(Referentiel.last.id)
        end
      end
    end
  end

  # l1, l2, l3 => l1, l3, l2
  # destroyed: l3, created: (l3, [l1]), morphed: (l2, [l1, l3])
  describe '#move_up' do
    let(:params) do
      { procedure_id: procedure.id, stable_id: third_coordinate.stable_id }
    end

    subject { patch :move_up, params: params, format: :turbo_stream }

    it do
      is_expected.to have_http_status(:ok)
      expect(flash.alert).to eq(nil)
      expect(second_coordinate.libelle).to eq('l3')
      expect(assigns(:coordinate)).to eq(second_coordinate)
      expect(assigns(:destroyed).libelle).to eq('l3')
      expect(extract_libelle(assigns(:created))).to eq(['l3', ['l1']])
      expect(morpheds).to eq([['l2', ['l1', 'l3']]])
    end
  end

  # l1, l2, l3 => l2, l1, l3
  # destroyed: l1, created: (l1, [l2]), morphed: (l2, [])
  describe '#move_down' do
    let(:params) do
      { procedure_id: procedure.id, stable_id: first_coordinate.stable_id }
    end

    subject { patch :move_down, params: params, format: :turbo_stream }

    it do
      is_expected.to have_http_status(:ok)
      expect(flash.alert).to eq(nil)

      expect(assigns(:coordinate)).to eq(second_coordinate)
      expect(assigns(:destroyed).libelle).to eq('l1')
      expect(extract_libelle(assigns(:created))).to eq(['l1', ['l2']])
      expect(morpheds).to eq([['l2', []]])
    end
  end

  describe '#move_and_morph' do
    # l1, l2, l3 => l2, l3, l1
    context 'move and morph down' do
      let(:params) do
        { procedure_id: procedure.id, stable_id: first_coordinate.stable_id, target_stable_id: third_coordinate.stable_id }
      end

      subject { patch :move_and_morph, params: params, format: :turbo_stream }

      it do
        is_expected.to have_http_status(:ok)
        expect(assigns(:coordinate)).to eq(first_coordinate)
        expect(assigns(:destroyed)).to eq(first_coordinate)
        expect(extract_libelle(assigns(:created))).to eq(['l1', ['l2', 'l3']])
        expect(morpheds).to eq([['l2', []], ['l3', ['l2']]])
      end
    end

    # l1, l2, l3 => l1, l3, l2
    context 'move and morph up' do
      let(:params) do
        { procedure_id: procedure.id, stable_id: third_coordinate.stable_id, target_stable_id: first_coordinate.stable_id }
      end

      subject { patch :move_and_morph, params: params, format: :turbo_stream }

      it do
        is_expected.to have_http_status(:ok)
        [first_coordinate, second_coordinate, third_coordinate].map(&:reload)
        expect(assigns(:coordinate).stable_id).to eq(second_coordinate.stable_id)
        expect(assigns(:destroyed).stable_id).to eq(second_coordinate.stable_id)
        expect(extract_libelle(assigns(:created))).to eq(['l3', ['l1']])
        expect(morpheds).to eq([['l3', ['l1']], ['l2', ['l1', 'l3']]])
      end
    end
  end

  # l1, l2, l3 => l1, l3
  # destroyed: l2, morphed: (l3, [l1])
  describe '#destroy' do
    let(:params) do
      { procedure_id: procedure.id, stable_id: second_coordinate.stable_id }
    end

    subject { delete :destroy, params: params, format: :turbo_stream }

    it do
      used_to_be_second_coordinate = second_coordinate

      is_expected.to have_http_status(:ok)
      expect(flash.alert).to eq(nil)
      expect(assigns(:coordinate)).to eq(used_to_be_second_coordinate)
      expect(assigns(:destroyed).libelle).to eq('l2')
      expect(morpheds).to eq([['l3', ['l1']]])
    end

    context 'rejected if type changed and routing involved' do
      let(:params) do
        { procedure_id: procedure.id, stable_id: third_coordinate.stable_id }
      end

      before do
        allow_any_instance_of(ProcedureRevisionTypeDeChamp).to receive(:used_by_routing_rules?).and_return(true)
      end

      it do
        is_expected.to have_http_status(:ok)
        expect(flash.alert).to include("utilisé pour le routage")
      end
    end
  end

  describe '#notice_explicative' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :explication }]) }
    let(:coordinate) { procedure.draft_revision.types_de_champ.first }
    let(:file) { Tempfile.new }
    let(:blob) { ActiveStorage::Blob.create_before_direct_upload!(filename: File.basename(file.path), byte_size: file.size, checksum: Digest::SHA256.file(file.path), content_type: 'text/plain') }

    context 'when sending a valid blob' do
      it 'attaches the blob and responds with 200' do
        expect { put :notice_explicative, format: :turbo_stream, params: { stable_id: coordinate.stable_id, procedure_id: procedure.id, blob_signed_id: blob.signed_id } }
          .to change { coordinate.reload.notice_explicative.attached? }
          .from(false).to(true)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '#nullify_referentiel' do
    let(:procedure) { create(:procedure) }
    let!(:type_de_champ) { create(:type_de_champ_drop_down_list, procedure:, referentiel:) }
    let(:referentiel) { create(:csv_referentiel, :with_items) }

    let(:params) do
      { procedure_id: procedure.id, stable_id: type_de_champ.stable_id }
    end

    subject { delete :nullify_referentiel, params: params, format: :turbo_stream }

    context 'working case with multi column file' do
      it 'nullifies referentiel' do
        expect { subject }.to not_change(Referentiel, :count).and not_change(ReferentielItem, :count)
        expect(type_de_champ.reload.referentiel).to be_nil
        expect(Referentiel.count).to eq 1
        expect(ReferentielItem.count).to eq 3
      end
    end
  end

  describe '#simplify' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
    let(:types_de_champ_public) { [{ type: :text, libelle: 'Ancien', stable_id: 123 }] }
    let(:rule) { LLM::LabelImprover::TOOL_NAME }
    let(:procedure_revision) { procedure.published_revision }
    let(:schema_hash) { Digest::SHA256.hexdigest(procedure_revision.schema_to_llm.to_json) }
    let(:llm_rule_suggestion) { create(:llm_rule_suggestion, procedure_revision:, schema_hash:, state: 'completed', rule: rule) }

    it 'renders label suggestions from stored LLMRuleSuggestion items' do
      llm_rule_suggestion_item = create(:llm_rule_suggestion_item,
        llm_rule_suggestion:,
        op_kind: 'update',
        stable_id: 123,
        payload: { 'stable_id' => 123, 'libelle' => 'Nouveau' },
        safety: 'safe',
        justification: 'clarity',
        confidence: 0.9)

      get :simplify, params: { procedure_id: procedure.id, llm_suggestion_rule_id: llm_rule_suggestion.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:component)).to be_an_instance_of(LLM::ImproveLabelComponent)
    end

    it 'redirect on unknown llm_suggestion' do
      get :simplify, params: { procedure_id: procedure.id, llm_suggestion_rule_id: 'unknown_rule' }
      expect(response).to redirect_to(simplify_index_admin_procedure_types_de_champ_path(procedure))
      expect(flash[:alert]).to eq("Suggestion non trouvée")
    end
  end

  describe '#simplify_index' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text, libelle: 'Ancien', stable_id: 123 }]) }
    let(:procedure_revision) { procedure.published_revision }
    let(:schema_hash) { Digest::SHA256.hexdigest(procedure_revision.schema_to_llm.to_json) }
    let(:rule) { LLM::LabelImprover::TOOL_NAME }
    let(:llm_rule_suggestion) { create(:llm_rule_suggestion, procedure_revision:, schema_hash:, state: 'completed', rule: rule) }

    it 'when suggestion are available, it list available rules and suggestion count' do
      llm_rule_suggestion = create(:llm_rule_suggestion, procedure_revision: procedure.published_revision, rule: LLM::ImproveLabelComponent.key, state: 'completed', schema_hash: Digest::SHA256.hexdigest(procedure.published_revision.schema_to_llm.to_json))
      create(:llm_rule_suggestion_item, llm_rule_suggestion:, stable_id: 123, op_kind: 'update', payload: { 'stable_id' => 123, 'libelle' => 'Nouveau' })
      get :simplify_index, params: { procedure_id: procedure.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:llm_rule_suggestions).first.id).to eq(llm_rule_suggestion.id)
      expect(assigns(:llm_rule_suggestions).first.items_count).to eq(1)
    end
  end

  describe '#accept_simplification' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
    let(:types_de_champ_public) do
      [
        { type: :text, libelle: 'A', stable_id: 123 },
        { type: :text, libelle: 'B' }
      ]
    end

    it 'applies only selected operations from posted changes_json' do
      suggestion = create(:llm_rule_suggestion, procedure_revision: procedure.published_revision, rule: LLM::LabelImprover::TOOL_NAME, state: 'completed', schema_hash: Digest::SHA256.hexdigest(procedure.published_revision.schema_to_llm.to_json))
      accepted_suggestion_item = create(:llm_rule_suggestion_item, llm_rule_suggestion: suggestion, op_kind: 'update', stable_id: 123, payload: { 'stable_id' => 123, 'libelle' => 'Nouveau' }, safety: 'safe', justification: 'clarity', confidence: 0.9)
      skipped_suggestion_item = create(:llm_rule_suggestion_item, llm_rule_suggestion: suggestion, op_kind: 'update', stable_id: 123, payload: { 'stable_id' => 123, 'libelle' => 'Nouveau' }, safety: 'safe', justification: 'clarity', confidence: 0.9)

      post :accept_simplification, params: {
        procedure_id: procedure.id,
        llm_suggestion_rule_id: suggestion.id,
        llm_rule_suggestion: {
          llm_rule_suggestion_items_attributes: {
            "0" => { id: accepted_suggestion_item.id, verify_status: 'accepted' },
            "1" => { id: skipped_suggestion_item.id, verify_status: 'skipped' }
          }
        }
      }

      expect(response).to redirect_to(simplify_index_admin_procedure_types_de_champ_path(procedure))

      libelles = procedure.draft_revision.reload.types_de_champ_public.map(&:libelle)
      expect(libelles).to include('Nouveau')
      expect(libelles).not_to include('A')

      expect(accepted_suggestion_item.reload.verify_status).to eq('accepted')
      expect(accepted_suggestion_item.applied_at).not_to be_nil
      expect(skipped_suggestion_item.reload.verify_status).to eq('skipped')
      expect(skipped_suggestion_item.reload.applied_at).to be_nil
    end
  end
end
