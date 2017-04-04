require 'spec_helper'

describe Admin::PrevisualisationsController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    subject { get :show, params: {procedure_id: procedure.id} }
    it { expect(subject.status).to eq(200) }
  end

end
