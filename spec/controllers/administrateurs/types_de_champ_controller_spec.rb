describe Administrateurs::TypesDeChampController, type: :controller do
  let(:procedure) do
    create(:procedure).tap do |p|
      p.draft_revision.add_type_de_champ(type_champ: :integer_number, libelle: 'l1')
      p.draft_revision.add_type_de_champ(type_champ: :integer_number, libelle: 'l2')
      p.draft_revision.add_type_de_champ(type_champ: :integer_number, libelle: 'l3')
      p.draft_revision.add_type_de_champ(type_champ: :yes_no, libelle: 'bon dossier', private: true)
    end
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
      let(:params) { default_params.deep_merge(type_de_champ: { libelle: '' }) }

      it do
        is_expected.to have_http_status(:ok)
        expect(assigns(:coordinate)).to be_nil
        expect(flash.alert).to eq(["Le champ « Libelle » doit être rempli"])
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
        expect(assigns(:coordinate)).to be_nil
        expect(flash.alert).to eq(["Le champ « Libelle » doit être rempli"])
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
  end
end
