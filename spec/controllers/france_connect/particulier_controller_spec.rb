describe FranceConnect::ParticulierController, type: :controller do
  let(:birthdate) { '20150821' }
  let(:email) { 'test@test.com' }

  let(:user_info) do
    {
      france_connect_particulier_id: 'blablabla',
      given_name: 'titi',
      family_name: 'toto',
      birthdate: birthdate,
      birthplace: '1234',
      gender: 'M',
      email_france_connect: email
    }
  end

  describe '#auth' do
    subject { get :login }

    it { is_expected.to have_http_status(:redirect) }
  end

  describe '#callback' do
    let(:code) { 'plop' }

    subject { get :callback, params: { code: code } }

    context 'when param code is missing' do
      let(:code) { nil }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when param code is empty' do
      let(:code) { '' }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when code is correct' do
      before do
        allow(FranceConnectService).to receive(:retrieve_user_informations_particulier)
          .and_return(FranceConnectInformation.new(user_info))
      end

      context 'when france_connect_particulier_id exist in database' do
        let!(:france_connect_information) { create(:france_connect_information, user_info) }

        it { expect { subject }.not_to change { FranceConnectInformation.count } }

        context 'when france_connect_particulier_id have an associate user' do
          let!(:user) { create(:user, email: 'plop@plop.com', france_connect_information: france_connect_information) }

          it do
            subject
            expect(user.reload.loged_in_with_france_connect).to eq(User.loged_in_with_france_connects.fetch(:particulier))
          end

          context 'and the user has a stored location' do
            let(:stored_location) { '/plip/plop' }
            before { controller.store_location_for(:user, stored_location) }

            it { is_expected.to redirect_to(stored_location) }
          end
        end

        context 'when france_connect_particulier_id does not have an associate user' do
          it { is_expected.to redirect_to(root_path) }

          it do
            subject
            expect(User.find_by(email: email)).not_to be_nil
          end
        end
      end

      context 'when france_connect_particulier_id does not exist in database' do
        it { expect { subject }.to change { FranceConnectInformation.count }.by(1) }

        describe 'FranceConnectInformation attributs' do
          let(:stored_fci) { FranceConnectInformation.last }

          before { subject }

          it { expect(stored_fci).to have_attributes(user_info.merge(birthdate: Time.zone.parse(birthdate))) }
        end

        it { is_expected.to redirect_to(root_path) }
      end
    end

    context 'when code is not correct' do
      before do
        allow(FranceConnectService).to receive(:retrieve_user_informations_particulier) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
        subject
      end

      it { expect(response).to redirect_to(new_user_session_path) }

      it { expect(flash[:alert]).to be_present }
    end
  end
end
