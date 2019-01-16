require 'spec_helper'

describe NewUser::CommencerController, type: :controller do
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
      end
    end

    context 'when the path is for a non-published procedure' do
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
  end

  describe '#commencer_test' do
    subject { get :commencer_test, params: { path: path } }

    context 'when the path is for a draft procedure' do
      let(:path) { draft_procedure.path }

      it 'renders the view' do
        expect(subject.status).to eq(200)
        expect(subject).to render_template('show')
        expect(assigns(:procedure)).to eq draft_procedure
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
    subject { get :sign_in, params: { path: published_procedure.path } }

    it 'set the path to return after sign-in to the dossier creation path' do
      subject
      expect(controller.stored_location_for(:user)).to eq(new_dossier_path(procedure_id: published_procedure.id))
    end

    it { expect(subject).to redirect_to(new_user_session_path) }
  end

  describe '#sign_up' do
    subject { get :sign_up, params: { path: published_procedure.path } }

    it 'set the path to return after sign-up to the dossier creation path' do
      subject
      expect(controller.stored_location_for(:user)).to eq(new_dossier_path(procedure_id: published_procedure.id))
    end

    it { expect(subject).to redirect_to(new_user_registration_path) }
  end
end
