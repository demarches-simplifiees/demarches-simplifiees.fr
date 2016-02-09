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
    subject { post :create, gestionnaire: { email: email } }

    context 'When email is valid' do
      before do
        subject
      end
      it { expect(response.status).to eq(302) }
      it { expect(response).to redirect_to admin_gestionnaires_path }

      describe 'Gestionnaire attributs in database' do
        let(:gestionnaire) { Gestionnaire.last }
        it { expect(gestionnaire.email).to eq(email) }
        it { expect(gestionnaire.administrateur_id).to eq(admin.id) }
      end
    end

    context 'when email is not valid' do
      before do
        subject
      end
    	let(:email) { 'piou' }
    	it { expect(response.status).to eq(302) }
    	it { expect{ response }.not_to change(Gestionnaire, :count) }
    end

    context 'when email is empty' do
      before do
        subject
      end
    	let(:email) { '' }
    	it { expect(response.status).to eq(302) }
    	it { expect{ response }.not_to change(Gestionnaire, :count) }
      it 'Notification email is not send' do
        expect(GestionnaireMailer).not_to receive(:new_gestionnaire)
        expect(GestionnaireMailer).not_to receive(:deliver_now!)
      end
    end

    context ' when email already exists' do
      let(:email) { 'test@plop.com' }
      before do
        subject
        post :create, gestionnaire: { email: email }
      end
      it { expect(response.status).to eq(302) }
      it { expect{ response }.not_to change(Gestionnaire, :count) }
    end

    context 'Email notification' do

      it 'Notification email is sent when email is valid' do
        expect(GestionnaireMailer).to receive(:new_gestionnaire).and_return(GestionnaireMailer)
        expect(GestionnaireMailer).to receive(:deliver_now!)
        subject
      end

      context 'is not sent when email is not valid' do
        let(:email) { 'testplop.com' }
        it {
          expect(GestionnaireMailer).not_to receive(:new_gestionnaire)
          expect(GestionnaireMailer).not_to receive(:deliver_now!)
          subject
        }
      end

      it 'is not sent when email already exists' do
        subject
        expect(GestionnaireMailer).not_to receive(:new_gestionnaire)
        expect(GestionnaireMailer).not_to receive(:deliver_now!)
        subject
      end

    end
  end
end