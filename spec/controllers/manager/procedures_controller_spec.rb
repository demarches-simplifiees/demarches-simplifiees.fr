describe Manager::ProceduresController, type: :controller do
  let(:super_admin) { create :super_admin }
  let(:administrateur) { create(:administrateur, email: super_admin.email) }
  let(:autre_administrateur) { administrateurs(:default_admin) }
  before { sign_in super_admin }

  describe '#whitelist' do
    let(:procedure) { create(:procedure) }

    before do
      post :whitelist, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.whitelisted?).to be_truthy }
  end

  describe '#hide_as_template' do
    let(:procedure) { create(:procedure) }

    before do
      post :hide_as_template, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.hidden_as_template?).to be_truthy }
  end

  describe '#unhide_as_template' do
    let(:procedure) { create(:procedure) }

    before do
      post :unhide_as_template, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.hidden_as_template?).to be_falsey }
  end

  describe '#show' do
    render_views

    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :repetition, children: [{ type: :text, libelle: 'sub type de champ' }] }]) }

    before do
      get :show, params: { id: procedure.id }
    end

    it { expect(response.body).to include('sub type de champ') }
    it { expect(response.body).to include('Hidden At As Template') }
  end

  describe '#discard' do
    let(:dossier) { create(:dossier, :accepte) }
    let(:procedure) { dossier.procedure }

    before do
      post :discard, params: { id: procedure.id }
      procedure.reload
      dossier.reload
    end

    it { expect(procedure.discarded?).to be_truthy }
    it { expect(dossier.hidden_by_administration?).to be_truthy }
  end

  describe '#restore' do
    let(:dossier) { create(:dossier, :accepte, :with_individual) }
    let(:procedure) { dossier.procedure }

    before do
      procedure.discard_and_keep_track!(super_admin)

      post :restore, params: { id: procedure.id }
      procedure.reload
    end

    it { expect(procedure.kept?).to be_truthy }
    it { expect(dossier.hidden_by_administration?).to be_falsey }
  end

  describe '#index' do
    render_views

    context 'sort by dossiers' do
      let!(:dossier) { create(:dossier) }

      before do
        get :index, params: { procedure: { direction: :asc, order: :dossiers } }
      end

      it { expect(response.body).to include('1 Dossier') }
    end
  end

  describe '#delete_administrateur' do
    let(:procedure) { create(:procedure, :with_service, administrateurs: [administrateur, autre_administrateur]) }
    let(:administrateur) { create(:administrateur, email: super_admin.email) }

    subject(:delete_request) { put :delete_administrateur, params: { id: procedure.id } }

    it "removes the current administrateur from the procedure" do
      delete_request
      expect(procedure.administrateurs).to eq([autre_administrateur])
    end

    context 'when the current administrateur has been added as instructeur too' do
      let(:instructeur) { create(:instructeur) }
      let(:administrateur) { create(:administrateur, email: super_admin.email, instructeur: instructeur) }

      before do
        procedure.groupe_instructeurs.map do |groupe_instructeur|
          instructeur.assign_to.create!(groupe_instructeur: groupe_instructeur, manager: true)
        end
      end

      it "removes the instructeur from the procedure" do
        delete_request
        instructeur.groupe_instructeurs.each do |groupe_instructeur|
          expect(groupe_instructeur.instructeurs).not_to include(instructeur)
        end
      end
    end
  end
end
