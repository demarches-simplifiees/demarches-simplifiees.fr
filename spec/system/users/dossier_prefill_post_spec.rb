describe 'Prefilling a dossier (with a POST request):' do
  let(:password) { 'my-s3cure-p4ssword' }

  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { procedure.dossiers.last }

  let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
  let(:type_de_champ_phone) { create(:type_de_champ_phone, procedure: procedure) }
  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }

  scenario "the user get the URL of a prefilled orphan brouillon dossier" do
    dossier_url = create_and_prefill_dossier_with_post_request

    expect(dossier_url).to eq(commencer_path(procedure.path, token: dossier.prefill_token))
  end

  describe 'visit the dossier URL' do
    context 'when authenticated' do
      it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
        let(:user) { create(:user, password: password) }

        before do
          visit "/users/sign_in"
          sign_in_with user.email, password

          visit create_and_prefill_dossier_with_post_request

          expect(page).to have_content('Vous avez un dossier prérempli')
          click_on 'Continuer à remplir mon dossier'
        end
      end
    end

    context 'when unauthenticated' do
      before { visit create_and_prefill_dossier_with_post_request }

      context 'when the user signs in with email and password' do
        it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
          let(:user) { create(:user, password: password) }

          before do
            click_on "J’ai déjà un compte"
            sign_in_with user.email, password

            expect(page).to have_content('Vous avez un dossier prérempli')
            click_on 'Continuer à remplir mon dossier'
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

            expect(page).to have_content('Vous avez un dossier prérempli')
            click_on 'Continuer à remplir mon dossier'
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

            expect(page).to have_content('Vous avez un dossier prérempli')
            click_on 'Continuer à remplir mon dossier'
          end
        end
      end
    end
  end

  private

  def create_and_prefill_dossier_with_post_request
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.post api_public_v1_dossiers_path(procedure),
      headers: { "Content-Type" => "application/json" },
      params: {
        "champ_#{type_de_champ_text.to_typed_id}" => text_value,
        "champ_#{type_de_champ_phone.to_typed_id}" => phone_value
      }.to_json
    JSON.parse(session.response.body)["dossier_url"].gsub("http://www.example.com", "")
  end
end
