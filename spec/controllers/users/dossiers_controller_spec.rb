require 'spec_helper'

describe Users::DossiersController, type: :controller do
  let(:user) { create(:user) }

  let(:procedure) { create(:procedure, :published) }
  let(:procedure_id) { procedure.id }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:dossier_id) { dossier.id }

  describe 'GET #new' do
    subject { get :new, params: { procedure_id: procedure_id } }

    context 'when params procedure_id is present' do
      context 'when procedure_id is valid' do
        context 'when user is logged in' do
          before do
            sign_in user
          end

          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to siret_dossier_path(id: Dossier.last) }

          it { expect { subject }.to change(Dossier, :count).by 1 }

          context 'when procedure is archived' do
            let(:procedure) { create(:procedure, :archived) }

            it { is_expected.to redirect_to dossiers_path }
          end
        end
        context 'when user is not logged' do
          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to new_user_session_path }
        end
      end

      context 'when procedure_id is not valid' do
        let(:procedure_id) { 0 }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to dossiers_path }
      end

      context 'when procedure is not published' do
        let(:procedure) { create(:procedure) }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to dossiers_path }

        context 'and brouillon param is passed' do
          subject { get :new, params: { procedure_id: procedure_id, brouillon: true } }

          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to siret_dossier_path(id: Dossier.last) }
        end
      end
    end
  end

  describe 'GET #commencer' do
    subject { get :commencer, params: { procedure_path: path } }
    let(:path) { procedure.path }

    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to new_users_dossier_path(procedure_id: procedure.id) }

    context 'when procedure path does not exist' do
      let(:path) { 'hello' }

      it { expect(subject).to redirect_to(root_path) }
    end
  end

  describe 'GET #commencer_test' do
    before do
      Flipflop::FeatureSet.current.test!.switch!(:publish_draft, true)
    end

    subject { get :commencer_test, params: { procedure_path: path } }
    let(:procedure) { create(:procedure, :with_path) }
    let(:path) { procedure.path }

    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to new_users_dossier_path(procedure_id: procedure.id, brouillon: true) }

    context 'when procedure path does not exist' do
      let(:path) { 'hello' }

      it { expect(subject).to redirect_to(root_path) }
    end
  end
end
