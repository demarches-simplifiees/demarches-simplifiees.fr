require 'spec_helper'

describe RootController, type: :controller do

  subject { get :index }

  context 'when User is connected' do
    before do
      sign_in create(:user)
    end

    it { expect(subject).to redirect_to(users_dossiers_path) }
  end

  context 'when Gestionnaire is connected' do
    before do
      sign_in create(:gestionnaire)
    end

    it { expect(subject).to redirect_to(backoffice_path) }
  end

  context 'when Administrateur is connected' do
    before do
      sign_in create(:administrateur)
    end

    it { expect(subject).to redirect_to(admin_procedures_path) }
  end

  context 'when nobody is connected' do
    it { expect(subject).to redirect_to(new_user_session_path) }
  end
end