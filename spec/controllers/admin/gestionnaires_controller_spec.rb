require 'spec_helper'

describe Admin::GestionnairesController, type: :controller  do
  let(:admin) { create(:administrateur) }
  before do
    sign_in admin
  end

  describe 'GET #index' do
  	subject { get :index }
  	it { expect(subject.status).to eq(200) }
  end

  describe 'POST #create' do
  	let(:email) { 'test@plop.com' }
  	before do
      post :create, gestionnaire: { email: email }
    end
  	it { expect(response.status).to eq(302) }
  	it { expect(response).to redirect_to admin_gestionnaires_path }

    describe 'Gestionnaire attributs in database' do
      let(:gestionnaire) { Gestionnaire.last }
      it { expect(gestionnaire.email).to eq(email) }
      it { expect(gestionnaire.administrateur_id).to eq(admin.id) }
    end

    context 'when email is not valid' do
    	let(:email) { 'piou' }
    	it { expect(response.status).to eq(302) }
    	it { expect{ response }.not_to change(Gestionnaire, :count) }
    end

    context 'when email is empty' do
    	let(:email) { '' }
    	it { expect(response.status).to eq(302) }
    	it { expect{ response }.not_to change(Gestionnaire, :count) }
    end

    context ' when email already exists' do
      let(:email) { 'test@plop.com' }
      before do
        post :create, gestionnaire: { email: email }
      end
      it { expect(response.status).to eq(302) }
      it { expect{ response }.not_to change(Gestionnaire, :count) }
    end

  end
end