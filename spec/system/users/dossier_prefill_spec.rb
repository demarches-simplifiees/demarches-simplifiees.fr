describe 'Prefilling a dossier:' do
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

    visit new_dossier_path(
      procedure_id: procedure.id,
      "champ_#{type_de_champ_text.to_typed_id}" => text_value,
      "champ_#{type_de_champ_phone.to_typed_id}" => phone_value
    )
  end

  context 'when the user already exists' do
    let(:password) { 'my-s3cure-p4ssword' }
    let!(:user) { create(:user, password: password) }

    scenario "the user has got a prefilled dossier after signing in" do
      expect(page).to have_content("Connectez-vous")
      sign_in_with user.email, password

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

  context 'when this is a new user' do
    before do
      allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: "c0d3"))
      allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(build(:france_connect_information))
    end

    scenario "the user has got a prefilled dossier after signing up" do
      expect(page).to have_content("Connectez-vous")
      page.find('.fr-connect').click

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
end
