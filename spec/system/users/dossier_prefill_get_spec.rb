describe 'Prefilling a dossier (with a GET request):' do
  let(:password) { 'my-s3cure-p4ssword' }

  let(:procedure) { create(:procedure, :published, opendata: true) }
  let(:dossier) { procedure.dossiers.last }

  let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
  let(:type_de_champ_phone) { create(:type_de_champ_phone, procedure: procedure) }
  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }

  context 'when authenticated' do
    it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
      let(:user) { create(:user, password: password) }

      before do
        visit "/users/sign_in"
        sign_in_with user.email, password

        visit commencer_path(
          path: procedure.path,
          "champ_#{type_de_champ_text.to_typed_id}" => text_value,
          "champ_#{type_de_champ_phone.to_typed_id}" => phone_value
        )

        click_on "Commencer la démarche"
      end
    end
  end

  context 'when unauthenticated' do
    before do
      visit commencer_path(
        path: procedure.path,
        "champ_#{type_de_champ_text.to_typed_id}" => text_value,
        "champ_#{type_de_champ_phone.to_typed_id}" => phone_value
      )
    end

    context 'when the user signs in with email and password' do
      it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
        let!(:user) { create(:user, password: password) }

        before do
          click_on "J’ai déjà un compte"
          sign_in_with user.email, password

          click_on "Commencer la démarche"
        end
      end
    end

    context 'when the user signs up with email and password' do
      it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
        let(:user_email) { generate :user_email }
        let(:user) { User.find_by(email: user_email) }

        before do
          click_on "Créer un compte #{APPLICATION_NAME}"

          sign_up_with user_email, password
          expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"

          click_confirmation_link_for user_email
          expect(page).to have_content('Votre compte a bien été confirmé.')

          click_on "Commencer la démarche"
        end
      end
    end

    context 'when the user signs up with FranceConnect' do
      it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
        let(:user) { User.last }

        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: "c0d3"))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(build(:france_connect_information))

          page.find('.fr-connect').click

          click_on "Commencer la démarche"
        end
      end
    end
  end
end
