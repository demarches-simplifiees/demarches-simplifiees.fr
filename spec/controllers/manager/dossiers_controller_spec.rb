include ActionView::Helpers::SanitizeHelper

describe Manager::DossiersController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  before do
    sign_in super_admin
    procedure = create(:procedure, :published, types_de_champ_public: types_de_champ)
    @dossier = create(:dossier, :en_construction, :with_populated_champs, procedure:)
  end

  let(:types_de_champ) { [] }

  render_views

  describe 'GET #index' do
    it "should list dossiers" do
      get :index
      expect(response.body).to include(@dossier.procedure.libelle)
    end
  end

  describe "GET #show" do
    let(:types_de_champ) {
      [
        { libelle: "Nom", mandatory: true }
      ]
    }

    before do
      get :show, params: { id: @dossier.id }
    end

    subject { strip_tags(response.body) }

    it { expect(subject).to match(%r{Nom\s+\*\s+Texte\s+🟢\s+rempli}) }
  end
end
