require 'spec_helper'

describe NewUser::CommencerController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }
  let(:procedure_id) { procedure.id }

  describe 'GET #commencer' do
    subject { get :commencer, params: { path: path } }
    let(:path) { procedure.path }

    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to new_dossier_path(procedure_id: procedure.id) }

    context 'when procedure path does not exist' do
      let(:path) { 'hello' }

      it { expect(subject).to redirect_to(root_path) }
    end
  end

  describe 'GET #commencer_test' do
    before do
      Flipflop::FeatureSet.current.test!.switch!(:publish_draft, true)
    end

    subject { get :commencer_test, params: { path: path } }
    let(:procedure) { create(:procedure, :with_path) }
    let(:path) { procedure.path }

    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to new_dossier_path(procedure_id: procedure.id, brouillon: true) }

    context 'when procedure path does not exist' do
      let(:path) { 'hello' }

      it { expect(subject).to redirect_to(root_path) }
    end
  end
end
