# frozen_string_literal: true

describe Administrateurs::TypesDeChampController, type: :controller do
  let(:procedure) do
    create(:procedure,
           types_de_champ_public: [
             { type: :integer_number, libelle: 'l1' },
             { type: :integer_number, libelle: 'l2' },
             { type: :drop_down_list, libelle: 'l3' }
           ],
           types_de_champ_private: [
             { type: :yes_no, libelle: 'bon dossier', private: true }
           ])
  end

  def first_coordinate = procedure.draft_revision.revision_types_de_champ_public.first
  def second_coordinate = procedure.draft_revision.revision_types_de_champ_public.reload.second
  def third_coordinate = procedure.draft_revision.revision_types_de_champ_public.reload.third

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
          after_stable_id: first_coordinate.stable_id
        }
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
          libelle: 'updated'
        }
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
        expect(flash.alert).to eq(["Le champ « Libelle » doit être rempli"])
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
end
