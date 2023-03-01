describe 'Prefilling a dossier (with a GET request):' do
  let(:password) { 'my-s3cure-p4ssword' }

  let(:procedure) { create(:procedure, :published, opendata: true) }
  let(:dossier) { procedure.dossiers.last }

  let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
  let(:type_de_champ_phone) { create(:type_de_champ_phone, procedure: procedure) }
  let(:type_de_champ_datetime) { create(:type_de_champ_datetime, procedure: procedure) }
  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }
  let(:datetime_value) { "2023-02-01T10:32" }

  context 'when authenticated' do
    it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
      let(:user) { create(:user, password: password) }

      before do
        visit "/users/sign_in"
        sign_in_with user.email, password

        visit commencer_path(
          path: procedure.path,
          "champ_#{type_de_champ_text.to_typed_id}" => text_value,
          "champ_#{type_de_champ_phone.to_typed_id}" => phone_value,
          "champ_#{type_de_champ_datetime.to_typed_id}" => datetime_value
        )

        click_on "Poursuivre mon dossier prérempli"
      end
    end
  end

  context 'when authenticated with existing dossier and session params (ie: reload the page)' do
    let(:user) { create(:user, password: password) }
    let(:dossier) { create(:dossier, :prefilled, procedure: procedure, prefill_token: "token", user: nil) }

    before do
      create(:champ_text, dossier: dossier, type_de_champ: type_de_champ_text, value: text_value)

      page.set_rack_session(prefill_token: "token")
      page.set_rack_session(prefill_params: { "action" => "commencer", "champ_#{type_de_champ_text.to_typed_id}" => text_value, "controller" => "users/commencer", "path" => procedure.path })

      visit "/users/sign_in"
      sign_in_with user.email, password

      visit commencer_path(
        path: procedure.path,
        "champ_#{type_de_champ_text.to_typed_id}" => text_value
      )

      click_on "Poursuivre mon dossier prérempli"
    end

    it "should not create a new dossier" do
      expect(Dossier.count).to eq(1)
      expect(dossier.reload.user).to eq(user)

      expect(page).to have_current_path(brouillon_dossier_path(dossier))
      expect(page).to have_field(type_de_champ_text.libelle, with: text_value)

      expect(page.get_rack_session[:prefill_token]).to be_nil
      expect(page.get_rack_session[:prefill_params]).to be_nil
    end
  end

  context 'when unauthenticated' do
    before do
      visit commencer_path(
        path: procedure.path,
        "champ_#{type_de_champ_text.to_typed_id}" => text_value,
        "champ_#{type_de_champ_phone.to_typed_id}" => phone_value,
        "champ_#{type_de_champ_datetime.to_typed_id}" => datetime_value
      )
    end

    context 'when the user signs in with email and password' do
      it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
        let!(:user) { create(:user, password: password) }

        before do
          click_on "J’ai déjà un compte"
          sign_in_with user.email, password

          click_on "Poursuivre mon dossier prérempli"
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

          click_on "Poursuivre mon dossier prérempli"
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

          click_on "Poursuivre mon dossier prérempli"
        end
      end
    end
  end
end
