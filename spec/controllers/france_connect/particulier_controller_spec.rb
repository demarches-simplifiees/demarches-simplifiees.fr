require 'spec_helper'

describe FranceConnect::ParticulierController, type: :controller do
  let(:code) { 'plop' }
  let(:given_name) { 'titi' }
  let(:family_name) { 'toto' }
  let(:birthdate) { '20150821' }
  let(:gender) { 'M' }
  let(:birthplace) { '1234' }
  let(:france_connect_particulier_id) { 'blabla' }
  let(:email) { 'test@test.com' }
  let(:password) { '' }

  let(:user_info) { Hashie::Mash.new(france_connect_particulier_id: france_connect_particulier_id, given_name: given_name, family_name: family_name, birthdate: birthdate, birthplace: birthplace, gender: gender, email: email, password: password) }

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
        end

        context 'when france_connect_particulier_id exist in database' do
          let!(:france_connect_information) { create(:france_connect_information, france_connect_particulier_id: france_connect_particulier_id, given_name: given_name, family_name: family_name, birthdate: birthdate, gender: gender, birthplace: birthplace) }

          context {
            subject { get :callback, code: code }

            it 'does not create a new france_connect_information in database' do
              expect { subject }.not_to change { FranceConnectInformation.count }
            end
          }

          context 'when france_connect_particulier_id have an associate user' do
            before do
              create(:user, email: email, france_connect_information: france_connect_information)

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

          context 'when france_connect_particulier_id does not have an associate user' do
            let(:salt) { FranceConnectSaltService.new(france_connect_information).salt }

            before do
              get :callback, code: code
            end

            it 'redirects to check email FC page' do
              expect(response).to redirect_to(france_connect_particulier_new_path(fci_id: france_connect_information.id, salt: salt))
            end
          end
        end

        context 'when france_connect_particulier_id does not exist in database' do
          let(:last_france_connect_information) { FranceConnectInformation.last }
          let(:salt) { FranceConnectSaltService.new(last_france_connect_information).salt }
          subject { get :callback, code: code }

          it { expect { subject }.to change { FranceConnectInformation.count }.by(1) }

          describe 'FranceConnectInformation attributs' do
            before do
              get :callback, code: code
            end

            subject { last_france_connect_information }

            it { expect(subject.gender).to eq gender }
            it { expect(subject.given_name).to eq given_name }
            it { expect(subject.family_name).to eq family_name }
            it { expect(subject.email_france_connect).to eq email }
            it { expect(subject.birthdate.to_time.to_i).to eq birthdate.to_time.to_i }
            it { expect(subject.birthplace).to eq birthplace }
            it { expect(subject.france_connect_particulier_id).to eq france_connect_particulier_id }
          end

          it 'redirects to check email FC page' do
            expect(subject).to redirect_to(france_connect_particulier_new_path(fci_id: last_france_connect_information.id, salt: salt))
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

  describe 'POST #check_email' do
    let(:email) { 'plop@gmail.com' }

    let!(:france_connect_information) { create(:france_connect_information) }
    let(:france_connect_information_id) { france_connect_information.id }
    let(:salt) { FranceConnectSaltService.new(france_connect_information).salt }

    subject { post :check_email, fci_id: france_connect_information_id, salt: salt, user: {email_france_connect: email} }

    context 'when salt and fci_id does not matches' do
      let(:france_connect_information_fake) { create(:france_connect_information, france_connect_particulier_id: 'iugfjh') }
      let(:france_connect_information_id) { france_connect_information_fake.id }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when salt and fci_id matches' do
      context 'when email is not used' do
        context 'when email is valid' do
          it { expect { subject }.to change { User.count }.by(1) }

          describe 'New user attributs' do
            before do
              subject
            end

            let(:user) { User.last }

            it { expect(user.email).to eq email }
            it { expect(user.france_connect_information).to eq france_connect_information }
          end
        end

        context 'when email is not valid' do
          let(:email) { 'kdjizjflk' }

          it { expect { subject }.not_to change { User.count } }
          it { is_expected.to redirect_to(france_connect_particulier_new_path fci_id: france_connect_information.id, salt: salt, user: {email_france_connect: email}) }
        end
      end

      context 'when email is used' do
        let!(:user) { create(:user, email: france_connect_information.email_france_connect) }
        let(:email) { france_connect_information.email_france_connect }
        let(:password) { user.password }

        before do
          subject
        end

        subject { post :check_email, fci_id: france_connect_information_id, salt: salt, user: {email_france_connect: email, password: password} }

        context 'when email and password couple is valid' do
          it { expect { subject }.not_to change { User.count } }

          describe 'Update user attributs' do
            before do
              subject
            end

            it { expect(user.france_connect_information).to eq france_connect_information }
          end
        end

        context 'when email and password couple is not valid' do
          let(:password) { 'fake' }

          it { expect(flash.alert).to eq 'Mot de passe invalide' }
        end
      end
    end
  end

  describe 'POST #create' do
    let!(:france_connect_information) { create(:france_connect_information, email_france_connect: email) }
    let(:france_connect_information_id) { france_connect_information.id }
    let(:salt) { FranceConnectSaltService.new(france_connect_information).salt }

    subject { post :create, fci_id: france_connect_information_id, salt: salt, user:{email_france_connect: france_connect_information.email_france_connect} }

    context 'when email is filled' do
      let(:email) { 'plop@gmail.com' }

      it { expect { subject }.to change { User.count }.by(1) }
      it { expect(subject).to redirect_to(root_path) }
    end

    context 'when email is incorrect' do
      let(:email) { '' }

      it { expect { subject }.not_to change { User.count } }
      it { expect(subject).to redirect_to(france_connect_particulier_new_path(fci_id: france_connect_information_id, salt: salt, user:{email_france_connect: france_connect_information.email_france_connect})) }
    end
  end
end
