require 'spec_helper'

describe AdministrationsController, type: :controller do
  let(:administration) { create :administration }

  describe 'GET #index' do
    subject { get :index }

    context 'when administration user is not connect' do
      it { expect(subject.status).to eq 302 }
    end

    context 'when administration user is connect' do
      before do
        sign_in administration
      end

      it { expect(subject.status).to eq 200 }
    end
  end
end
