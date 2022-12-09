describe 'Prefilling a dossier:' do
  let(:password) { 'my-s3cure-p4ssword' }
  let(:siret) { '41816609600051' }

  let(:procedure) { create(:procedure, :published, opendata: true) }
  let(:dossier) { procedure.dossiers.last }

  let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
  let(:type_de_champ_phone) { create(:type_de_champ_phone, procedure: procedure) }
  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))

    visit commencer_path(
      path: procedure.path,
      "champ_#{type_de_champ_text.to_typed_id}" => text_value,
      "champ_#{type_de_champ_phone.to_typed_id}" => phone_value
    )
  end

  shared_examples "the user has got a prefilled dossier" do
    scenario "the user has got a prefilled dossier" do
      click_on "Commencer la démarche"

      expect(page).to have_current_path siret_dossier_path(procedure.dossiers.last)
      fill_in 'Numéro SIRET', with: siret
      click_on 'Valider'

      expect(page).to have_current_path(etablissement_dossier_path(dossier))
      expect(page).to have_content('OCTO TECHNOLOGY')
      click_on 'Continuer avec ces informations'

      expect(page).to have_current_path(brouillon_dossier_path(dossier))
      expect(page).to have_field(type_de_champ_text.libelle, with: text_value)
      expect(page).to have_field(type_de_champ_phone.libelle, with: phone_value)
      expect(page).to have_css('.field_with_errors', text: type_de_champ_phone.libelle)
    end
  end

  context 'when the user signs in with email and password' do
    it_behaves_like "the user has got a prefilled dossier" do
      let!(:user) { create(:user, password: password) }

      before do
        click_on "J’ai déjà un compte"
        sign_in_with user.email, password
      end
    end
  end

  context 'when the user signs up with email and password' do
    it_behaves_like "the user has got a prefilled dossier" do
      let(:user_email) { generate :user_email }

      before do
        click_on "Créer un compte #{APPLICATION_NAME}"

        sign_up_with user_email, password
        expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"

        click_confirmation_link_for user_email
        expect(page).to have_content('Votre compte a bien été confirmé.')
      end
    end
  end

  context 'when the user signs up with FranceConnect' do
    it_behaves_like "the user has got a prefilled dossier" do
      before do
        allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: "c0d3"))
        allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(build(:france_connect_information))

        page.find('.fr-connect').click
      end
    end
  end
end
