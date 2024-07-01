describe 'Prefilling a dossier (with a GET request):', js: true do
  let(:password) { SECURE_PASSWORD }

  let(:types_de_champ_public) do
    [
      { type: :text },
      { type: :phone },
      { type: :rna },
      { type: :siret },
      { type: :datetime },
      { type: :multiple_drop_down_list },
      { type: :epci },
      { type: :annuaire_education },
      { type: :dossier_link },
      { type: :communes },
      { type: :address },
      { type: :repetition, children: [{ type: :text }, { type: :decimal_number }] }
    ]
  end
  let(:procedure) { create(:procedure, :for_individual, :published, opendata: true, types_de_champ_public:) }
  let(:dossier) { procedure.dossiers.last }
  let(:types_de_champ) { procedure.active_revision.types_de_champ_public }

  let(:type_de_champ_text) { types_de_champ[0] }
  let(:type_de_champ_phone) { types_de_champ[1] }
  let(:type_de_champ_rna) { types_de_champ[2] }
  let(:type_de_champ_siret) { types_de_champ[3] }
  let(:type_de_champ_datetime) { types_de_champ[4] }
  let(:type_de_champ_multiple_drop_down_list) { types_de_champ[5] }
  let(:type_de_champ_epci) { types_de_champ[6] }
  let(:type_de_champ_annuaire_education) { types_de_champ[7] }
  let(:type_de_champ_dossier_link) { types_de_champ[8] }
  let(:type_de_champ_commune) { types_de_champ[9] }
  let(:type_de_champ_address) { types_de_champ[10] }
  let(:type_de_champ_repetition) { types_de_champ[11] }

  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }
  let(:rna_value) { 'W595001988' }
  let(:siret_value) { '41816609600051' }
  let(:datetime_value) { "2023-02-01T10:32" }
  let(:multiple_drop_down_list_values) {
    [
      type_de_champ_multiple_drop_down_list.drop_down_list_enabled_non_empty_options.first,
      type_de_champ_multiple_drop_down_list.drop_down_list_enabled_non_empty_options.last
    ]
  }
  let(:epci_value) { ['01', '200029999'] }
  let(:dossier_link_value) { '42' }
  let(:commune_value) { ['01540', '01457'] }
  let(:commune_libelle) { 'Vonnas (01540)' }
  let(:address_value) { "20 Avenue de Ségur 75007 Paris" }
  let(:sub_types_de_champ_repetition) { procedure.active_revision.children_of(type_de_champ_repetition) }
  let(:text_repetition_libelle) { sub_types_de_champ_repetition.first.libelle }
  let(:integer_repetition_libelle) { sub_types_de_champ_repetition.second.libelle }
  let(:text_repetition_value) { "First repetition text" }
  let(:integer_repetition_value) { "42" }
  let(:annuaire_education_value) { '0050009H' }
  let(:prenom_value) { 'Jean' }
  let(:nom_value) { 'Dupont' }
  let(:genre_value) { 'M.' }

  let(:entry_path) {
    commencer_path(
      path: procedure.path,
      "champ_#{type_de_champ_text.to_typed_id_for_query}" => text_value,
      "champ_#{type_de_champ_phone.to_typed_id_for_query}" => phone_value,
      "champ_#{type_de_champ_datetime.to_typed_id_for_query}" => datetime_value,
      "champ_#{type_de_champ_multiple_drop_down_list.to_typed_id_for_query}" => multiple_drop_down_list_values,
      "champ_#{type_de_champ_epci.to_typed_id_for_query}" => epci_value,
      "champ_#{type_de_champ_dossier_link.to_typed_id_for_query}" => dossier_link_value,
      "champ_#{type_de_champ_commune.to_typed_id_for_query}" => commune_value,
      "champ_#{type_de_champ_address.to_typed_id_for_query}" => address_value,
      "champ_#{type_de_champ_siret.to_typed_id_for_query}" => siret_value,
      "champ_#{type_de_champ_rna.to_typed_id_for_query}" => rna_value,
      "champ_#{type_de_champ_repetition.to_typed_id_for_query}" => [
        {
          "champ_#{sub_types_de_champ_repetition.first.to_typed_id_for_query}": text_repetition_value,
          "champ_#{sub_types_de_champ_repetition.second.to_typed_id_for_query}": integer_repetition_value
        }
      ],
      "champ_#{type_de_champ_annuaire_education.to_typed_id_for_query}" => annuaire_education_value,
      "identite_prenom" => prenom_value,
      "identite_nom" => nom_value,
      "identite_genre" => genre_value
    )
  }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\//)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))

    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siret_value[0..8]}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'))

    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{rna_value}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/associations.json'))
  end

  context 'when authenticated' do
    it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
      let(:user) { create(:user, password: password) }

      before do
        visit "/users/sign_in"
        sign_in_with user.email, password
        visit entry_path

        click_on "Poursuivre mon dossier prérempli"
      end
    end
  end

  context 'when authenticated with existing dossier and session params (ie: reload the page)' do
    let(:user) { create(:user, password: password) }
    let(:dossier) { create(:dossier, :prefilled, procedure:, prefill_token: "token", user: nil) }
    let(:types_de_champ_public) { [{}] }

    before do
      dossier.champs.first.update(value: text_value)
      page.set_rack_session(prefill_token: "token")
      page.set_rack_session(prefill_params_digest: PrefillChamps.digest({ "champ_#{type_de_champ_text.to_typed_id}" => text_value }))

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
      expect(page.get_rack_session[:prefill_params_digest]).to be_nil
    end
  end

  context 'when unauthenticated' do
    before { visit entry_path }

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
          expect(page).to have_content "nous avons besoin de vérifier votre adresse électronique #{user_email}"

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
