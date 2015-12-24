require 'spec_helper'

describe FranceConnect::ParticulierController, type: :controller do
  let(:code) { 'plop' }
  let(:given_name) { 'titi' }
  let(:family_name) { 'toto' }
  let(:birthdate) { '20150821' }
  let(:gender) { 'M' }
  let(:birthplace) { '1234' }
  let(:france_connect_particulier_id) { 'blabla' }
  let(:email) { '' }

  let(:user_info) { Hashie::Mash.new(france_connect_particulier_id: france_connect_particulier_id, given_name: given_name, family_name: family_name, birthdate: birthdate, birthplace: birthplace, gender: gender, email: email) }

  describe '.login' do
    it 'redirect to france connect serveur' do
      get :login
      expect(response.status).to eq(302)
    end
  end

  describe '.callback' do
    context 'when param code is missing' do
      it 'redirect to login page' do
        get :callback
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when params code is present' do
      context 'when code is correct' do
        before do
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(user_info)
          get :callback, code: code
        end

        context 'when france_connect_particulier_id exist in database' do
          before do
            create(:user, france_connect_particulier_id: france_connect_particulier_id, email: email, given_name: given_name, family_name: family_name, birthdate: birthdate, gender: gender, birthplace: birthplace)
            get :callback, code: code
          end

          let(:email) { 'plop@plop.com' }
          let(:current_user) { User.find_by_email(email) }
          let(:stored_location) { '/plip/plop' }

          it 'current user have attribut loged_in_with_france_connect? at true' do
            expect(current_user.loged_in_with_france_connect?).to be_truthy
          end

          it 'redirect to stored location' do
            subject.store_location_for(:user, stored_location)
            get :callback, code: code
            expect(response).to redirect_to(stored_location)
          end
        end

        context 'when france_connect_particulier_id does not exist in database' do
          it 'redirects to check email FC page' do
            expect(response).to redirect_to(france_connect_particulier_new_path(user: user_info))
          end
        end
      end

      context 'when code is not correct' do
        before do
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
          get :callback, code: code
        end

        it 'redirect to login page' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'display error message' do
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe 'POST #create' do
    let(:email) { 'plop@gmail.com' }

    subject { post :create, user: user_info }

    context 'when email is filled' do
      it { expect { subject }.to change { User.count }.by(1) }

      it 'redirects user root page' do
        subject
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when email is incorrect' do
      let(:email) { '' }

      it { expect { subject }.to change { User.count }.by(0) }

      it 'redirect to check email FC page' do
        subject
        expect(response).to redirect_to(france_connect_particulier_new_path(user: user_info))
      end
    end
  end
end
