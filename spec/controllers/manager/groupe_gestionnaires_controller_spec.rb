# frozen_string_literal: true

describe Manager::GroupeGestionnairesController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }

  before { sign_in super_admin }

  describe '#index' do
    render_views

    before do
      groupe_gestionnaire
      get :index
    end

    it { expect(response.body).to include(groupe_gestionnaire.name) }
  end

  describe '#show' do
    render_views

    before do
      get :show, params: { id: groupe_gestionnaire.id }
    end

    it { expect(response.body).to include(groupe_gestionnaire.name) }
  end

  describe '#add_gestionnaire' do
    before do
      post :add_gestionnaire,
        params: {
          id: groupe_gestionnaire.id,
          emails: new_gestionnaire_email,
        }
    end

    context 'of a new gestionnaire' do
      let(:new_gestionnaire_email) { 'new_gestionnaire@mail.com' }

      it do
        expect(groupe_gestionnaire.gestionnaires.map(&:email)).to include(new_gestionnaire_email)
        expect(flash.notice).to be_present
        expect(response).to redirect_to(manager_groupe_gestionnaire_path(groupe_gestionnaire))
      end
    end
  end

  describe '#remove_gestionnaire' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:new_gestionnaire) { create(:gestionnaire) }

    before do
      groupe_gestionnaire.gestionnaires << gestionnaire << new_gestionnaire
    end

    def remove_gestionnaire(gestionnaire)
      delete :remove_gestionnaire,
        params: {
          id: groupe_gestionnaire.id,
          gestionnaire: { id: gestionnaire.id },
        }
    end

    context 'when there are many gestionnaires' do
      before { remove_gestionnaire(new_gestionnaire) }

      it do
        expect(groupe_gestionnaire.gestionnaires).to include(gestionnaire)
        expect(groupe_gestionnaire.reload.gestionnaires.count).to eq(1)
        expect(response).to redirect_to(manager_groupe_gestionnaire_path(groupe_gestionnaire))
      end
    end

    context 'when there is only one gestionnaire' do
      before do
        remove_gestionnaire(new_gestionnaire)
        remove_gestionnaire(gestionnaire)
      end

      it do
        expect(groupe_gestionnaire.gestionnaires).to include(gestionnaire)
        expect(groupe_gestionnaire.gestionnaires.count).to eq(1)
        expect(flash.alert).to eq('Suppression impossible : il doit y avoir au moins un gestionnaire dans le groupe racine')
        expect(response).to redirect_to(manager_groupe_gestionnaire_path(groupe_gestionnaire))
      end
    end
  end
end
