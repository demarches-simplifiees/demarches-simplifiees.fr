describe Users::CommencerController, type: :controller do
  let(:user) { create(:user) }
  let(:published_procedure) { create(:procedure, :published) }
  let(:draft_procedure) { create(:procedure, :with_path) }

  describe '#commencer' do
    subject { get :commencer, params: { path: path } }

    context 'when the path is for a published procedure' do
      let(:path) { published_procedure.path }

      it 'renders the view' do
        expect(subject.status).to eq(200)
        expect(subject).to render_template('show')
        expect(assigns(:procedure)).to eq published_procedure
        expect(assigns(:revision)).to eq published_procedure.published_revision
      end
    end

    context 'when the path is for a draft procedure' do
      let(:path) { draft_procedure.path }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end

    context 'when the path does not exist' do
      let(:path) { 'hello' }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end

    context 'when procedure without service is closed' do
      it 'works' do
        published_procedure.service = nil
        published_procedure.organisation = "hello"
        published_procedure.close!
        get :commencer, params: { path: published_procedure.path }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when procedure with service is closed' do
      it 'works' do
        published_procedure.service = create(:service)
        published_procedure.close!
        get :commencer, params: { path: published_procedure.path }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when procedure has a replaced_by_procedure' do
      let(:path) { published_procedure.path }

      it 'redirects to new procedure' do
        replaced_by_procedure = create(:procedure, :published)
        published_procedure.update!(replaced_by_procedure_id: replaced_by_procedure.id)
        published_procedure.close!
        expect(subject).to redirect_to(commencer_path(path: replaced_by_procedure.path))
      end
    end
  end

  describe '#commencer_test' do
    subject { get :commencer_test, params: { path: path } }

    context 'when the path is for a draft procedure' do
      let(:path) { draft_procedure.path }

      it 'renders the view' do
        expect(subject.status).to eq(200)
        expect(subject).to render_template('show')
        expect(assigns(:procedure)).to eq draft_procedure
        expect(assigns(:revision)).to eq draft_procedure.draft_revision
      end
    end

    context 'when the path is for a published procedure' do
      let(:path) { published_procedure.path }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end

    context 'when the path does not exist' do
      let(:path) { 'hello' }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end
  end

  describe '#sign_in' do
    context 'for a published procedure' do
      subject { get :sign_in, params: { path: published_procedure.path } }

      it 'set the path to return after sign-in to the procedure start page' do
        subject
        expect(controller.stored_location_for(:user)).to eq(commencer_path(path: published_procedure.path))
      end

      it { expect(subject).to redirect_to(new_user_session_path) }
    end

    context 'for a draft procedure' do
      subject { get :sign_in, params: { path: draft_procedure.path } }

      it 'set the path to return after sign-in to the draft procedure start page' do
        subject
        expect(controller.stored_location_for(:user)).to eq(commencer_test_path(path: draft_procedure.path))
      end

      it { expect(subject).to redirect_to(new_user_session_path) }
    end

    context 'when the path doesn’t exist' do
      subject { get :sign_in, params: { path: 'hello' } }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end
  end

  describe '#sign_up' do
    context 'for a published procedure' do
      subject { get :sign_up, params: { path: published_procedure.path } }

      it 'set the path to return after sign-up to the procedure start page' do
        subject
        expect(controller.stored_location_for(:user)).to eq(commencer_path(path: published_procedure.path))
      end

      it { expect(subject).to redirect_to(new_user_registration_path) }
    end

    context 'for a draft procedure' do
      subject { get :sign_up, params: { path: draft_procedure.path } }

      it 'set the path to return after sign-up to the draft procedure start page' do
        subject
        expect(controller.stored_location_for(:user)).to eq(commencer_test_path(path: draft_procedure.path))
      end

      it { expect(subject).to redirect_to(new_user_registration_path) }
    end

    context 'when the path doesn’t exist' do
      subject { get :sign_up, params: { path: 'hello' } }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end
  end

  describe '#france_connect' do
    context 'for a published procedure' do
      subject { get :france_connect, params: { path: published_procedure.path } }

      it 'set the path to return after sign-up to the procedure start page' do
        subject
        expect(controller.stored_location_for(:user)).to eq(commencer_path(path: published_procedure.path))
      end

      it { expect(subject).to redirect_to(france_connect_particulier_path) }
    end

    context 'for a draft procedure' do
      subject { get :france_connect, params: { path: draft_procedure.path } }

      it 'set the path to return after sign-up to the draft procedure start page' do
        subject
        expect(controller.stored_location_for(:user)).to eq(commencer_test_path(path: draft_procedure.path))
      end

      it { expect(subject).to redirect_to(france_connect_particulier_path) }
    end

    context 'when the path doesn’t exist' do
      subject { get :france_connect, params: { path: 'hello' } }

      it 'redirects with an error message' do
        expect(subject).to redirect_to(root_path)
      end
    end
  end

  describe '#dossier_vide_pdf' do
    before { get :dossier_vide_pdf, params: { path: procedure.path } }

    context 'published procedure' do
      let(:procedure) { create(:procedure, :published, :with_service, :with_path) }

      it 'works' do
        expect(response).to have_http_status(:success)
      end
    end
    context 'not published procedure' do
      let(:procedure) { create(:procedure, :with_service, :with_path) }

      it 'redirects to procedure not found' do
        expect(response).to have_http_status(302)
      end
    end
  end

  describe '#dossier_vide_test_pdf' do
    render_views
    before { get :dossier_vide_pdf_test, params: { path: procedure.path }, format: :pdf }

    context 'not published procedure with service' do
      let(:procedure) { create(:procedure, :with_service, :with_path) }

      it 'works' do
        expect(response).to have_http_status(:success)
      end
    end
    context 'not published procedure without service' do
      let(:procedure) { create(:procedure, :with_path, service: nil, organisation: nil) }

      it 'works' do
        expect(response).to have_http_status(:success)
      end
    end
    context 'published procedure' do
      let(:procedure) { create(:procedure, :published, :with_service, :with_path) }
      it 'redirect to procedure not found' do
        expect(response).to have_http_status(302)
      end
    end
  end
end
