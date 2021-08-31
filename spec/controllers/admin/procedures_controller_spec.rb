require 'uri'

describe Admin::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }

  let(:bad_procedure_id) { 100000 }

  let(:path) { 'ma-jolie-demarche' }
  let(:libelle) { 'Démarche de test' }
  let(:description) { 'Description de test' }
  let(:organisation) { 'Organisation de test' }
  let(:direction) { 'Direction de test' }
  let(:cadre_juridique) { 'cadre juridique' }
  let(:duree_conservation_dossiers_dans_ds) { 3 }
  let(:duree_conservation_dossiers_hors_ds) { 6 }
  let(:monavis_embed) { nil }
  let(:lien_site_web) { 'http://mon-site.gouv.fr' }

  let(:procedure_params) {
    {
      path: path,
      libelle: libelle,
      description: description,
      organisation: organisation,
      direction: direction,
      cadre_juridique: cadre_juridique,
      duree_conservation_dossiers_dans_ds: duree_conservation_dossiers_dans_ds,
      duree_conservation_dossiers_hors_ds: duree_conservation_dossiers_hors_ds,
      monavis_embed: monavis_embed,
      lien_site_web: lien_site_web
    }
  }

  before do
    sign_in(admin.user)
  end

  describe 'PUT #archive' do
    let(:procedure) { create(:procedure, :published, administrateur: admin, lien_site_web: lien_site_web) }

    context 'when admin is the owner of the procedure' do
      before do
        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      context 'when owner want archive procedure' do
        it { expect(procedure.close?).to be_truthy }
        it { expect(response).to redirect_to :admin_procedures }
        it { expect(flash[:notice]).to have_content 'Démarche close' }
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out(admin.user)
        sign_in(admin_2.user)

        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      it { expect(response).to redirect_to :admin_procedures }
      it { expect(flash[:alert]).to have_content 'Démarche inexistante' }
    end
  end

  describe 'PUT #clone' do
    let!(:procedure) { create(:procedure, :with_notice, :with_deliberation, administrateur: admin) }
    let(:params) { { procedure_id: procedure.id } }
    subject { put :clone, params: params }

    before do
      response = Typhoeus::Response.new(code: 200, body: 'Hello world')
      Typhoeus.stub(/active_storage\/disk/).and_return(response)
    end

    it { expect { subject }.to change(Procedure, :count).by(1) }

    context 'when admin is the owner of the procedure' do
      before { subject }

      it 'creates a new procedure and redirect to it' do
        expect(response).to redirect_to edit_admin_procedure_path(id: Procedure.last.id)
        expect(Procedure.last.cloned_from_library).to be_falsey
        expect(Procedure.last.notice.attached?).to be_truthy
        expect(Procedure.last.deliberation.attached?).to be_truthy
        expect(flash[:notice]).to have_content 'Démarche clonée'
      end

      context 'when the procedure is cloned from the library' do
        let(:params) { { procedure_id: procedure.id, from_new_from_existing: true } }

        it { expect(Procedure.last.cloned_from_library).to be(true) }
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out(admin.user)
        sign_in(admin_2.user)
        subject
      end

      it 'creates a new procedure and redirect to it' do
        expect(response).to redirect_to edit_admin_procedure_path(id: Procedure.last.id)
        expect(flash[:notice]).to have_content 'Démarche clonée'
      end
    end
  end
end
