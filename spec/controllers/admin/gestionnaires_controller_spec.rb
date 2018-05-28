require 'spec_helper'

describe Admin::GestionnairesController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:email_2) { 'plip@octo.com' }
  let(:admin_2) { create :administrateur, email: email_2 }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    subject { get :index }
    it { expect(subject.status).to eq(200) }
  end

  describe 'GET #index with sorting and pagination' do
    subject {
      get :index, params: {
        'gestionnaires_smart_listing[page]': 1,
        'gestionnaires_smart_listing[per_page]': 10,
        'gestionnaires_smart_listing[sort][email]': 'asc'
      }
    }

    it { expect(subject.status).to eq(200) }
  end

  describe 'POST #create' do
    let(:email) { 'test@plop.com' }
    let(:procedure_id) { nil }
    subject { post :create, params: { gestionnaire: { email: email }, procedure_id: procedure_id } }

    context 'When email is valid' do
      before do
        subject
      end

      let(:gestionnaire) { Gestionnaire.last }

      it { expect(response.status).to eq(302) }
      it { expect(response).to redirect_to admin_gestionnaires_path }

      context 'when procedure_id params is not null' do
        let(:procedure) { create :procedure }
        let(:procedure_id) { procedure.id }

        it { expect(response.status).to eq(302) }
        it { expect(response).to redirect_to admin_procedure_accompagnateurs_path(procedure_id: procedure_id) }
      end

      describe 'Gestionnaire attributs in database' do
        it { expect(gestionnaire.email).to eq(email) }
      end

      describe 'New gestionnaire is assign to the admin' do
        it { expect(gestionnaire.administrateurs).to include admin }
        it { expect(admin.gestionnaires).to include gestionnaire }
      end
    end

    context 'when email is not valid' do
      before do
        subject
      end
      let(:email) { 'piou' }
      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Gestionnaire, :count) }
      it { expect(flash[:alert]).to be_present }

      describe 'Email Notification' do
        it {
          expect(GestionnaireMailer).not_to receive(:new_gestionnaire)
          expect(GestionnaireMailer).not_to receive(:deliver_later)
          subject
        }
      end
    end

    context 'when email is empty' do
      before do
        subject
      end
      let(:email) { '' }
      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Gestionnaire, :count) }

      it 'Notification email is not send' do
        expect(GestionnaireMailer).not_to receive(:new_gestionnaire)
        expect(GestionnaireMailer).not_to receive(:deliver_later)
      end
    end

    context 'when email is already assign at the admin' do
      before do
        create :gestionnaire, email: email, administrateurs: [admin]
        subject
      end

      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Gestionnaire, :count) }
      it { expect(flash[:alert]).to be_present }

      describe 'Email notification' do
        it 'is not sent when email already exists' do
          expect(GestionnaireMailer).not_to receive(:new_gestionnaire)
          expect(GestionnaireMailer).not_to receive(:deliver_later)

          subject
        end
      end
    end

    context 'when an other admin will add the same email' do
      let(:gestionnaire) { Gestionnaire.find_by(email: email) }

      before do
        create :gestionnaire, email: email, administrateurs: [admin]

        sign_out admin
        sign_in admin_2

        subject
      end

      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Gestionnaire, :count) }
      it { expect(flash[:notice]).to be_present }

      it { expect(admin_2.gestionnaires).to include gestionnaire }
      it { expect(gestionnaire.administrateurs.size).to eq 2 }
    end

    context 'when an other admin will add the same email with some uppercase in it' do
      let(:email) { 'Test@Plop.com' }
      let(:gestionnaire) { Gestionnaire.find_by(email: email.downcase) }

      before do
        create :gestionnaire, email: email, administrateurs: [admin]

        sign_out admin
        sign_in admin_2

        subject
      end

      it { expect(admin_2.gestionnaires).to include gestionnaire }
    end

    context 'Email notification' do
      it 'Notification email is sent when accompagnateur is create' do
        expect_any_instance_of(Gestionnaire).to receive(:invite!)
        subject
      end
    end

    context 'unified login' do
      before do
        subject
      end

      it "creates associated user with same credentials" do
        gestionnaire = controller.instance_variable_get(:@gestionnaire)
        user = User.find_by(email: gestionnaire.email)
        expect(user.valid_password?(gestionnaire.password)).to be(true)
      end

      context 'invalid email' do
        let(:email) { 'fail' }

        it "won't create associated user" do
          expect(User.where(email: email).exists?).to be(false)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:email) { 'test@plop.com' }
    let!(:admin) { create :administrateur }
    let!(:gestionnaire) { create :gestionnaire, email: email, administrateurs: [admin] }

    subject { delete :destroy, params: { id: gestionnaire.id } }

    context "when gestionaire_id is valid" do
      before do
        subject
        admin.reload
        gestionnaire.reload
      end

      it { expect(response.status).to eq(302) }
      it { expect(response).to redirect_to admin_gestionnaires_path }
      it { expect(admin.gestionnaires).not_to include gestionnaire }
      it { expect(gestionnaire.administrateurs).not_to include admin }
    end

    it { expect { subject }.not_to change(Gestionnaire, :count) }
  end
end
