# frozen_string_literal: true

describe 'Prefilling a dossier (with a POST request):', js: true do
  let(:password) { SECURE_PASSWORD }

  let(:types_de_champ_public) do
    [
      { type: :text },
      { type: :phone },
      { type: :siret },
      { type: :datetime },
      { type: :multiple_drop_down_list },
      { type: :epci },
      { type: :dossier_link },
      { type: :communes },
      { type: :address },
      { type: :repetition, children: [{ type: :text }, { type: :decimal_number }] }
    ]
  end
  let(:procedure) { create(:procedure, :for_individual, :published, types_de_champ_public:) }
  let(:dossier) { procedure.dossiers.last }
  let(:linked_dossier) { create(:dossier, :en_construction, procedure:) }
  let(:types_de_champ) { procedure.active_revision.types_de_champ_public }

  let(:type_de_champ_text) { types_de_champ[0] }
  let(:type_de_champ_phone) { types_de_champ[1] }
  let(:type_de_champ_siret) { types_de_champ[2] }
  let(:type_de_champ_datetime) { types_de_champ[3] }
  let(:type_de_champ_multiple_drop_down_list) { types_de_champ[4] }
  let(:type_de_champ_epci) { types_de_champ[5] }
  let(:type_de_champ_dossier_link) { types_de_champ[6] }
  let(:type_de_champ_commune) { types_de_champ[7] }
  let(:type_de_champ_address) { types_de_champ[8] }
  let(:type_de_champ_repetition) { types_de_champ[9] }

  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }
  let(:siret_value) { '41816609600051' }
  let(:datetime_value) { "2023-02-01T10:32" }
  let(:multiple_drop_down_list_values) {
    [
      type_de_champ_multiple_drop_down_list.drop_down_options.first,
      type_de_champ_multiple_drop_down_list.drop_down_options.last
    ]
  }
  let(:epci_value) { ['01', '200029999'] }
  let(:commune_value) { ['01540', '01457'] }
  let(:commune_libelle) { 'Vonnas (01540)' }
  let(:address_value) { "20 Avenue de Ségur 75007 Paris" }
  let(:sub_type_de_champs_repetition) { procedure.active_revision.children_of(type_de_champ_repetition) }
  let(:text_repetition_libelle) { sub_type_de_champs_repetition.first.libelle }
  let(:integer_repetition_libelle) { sub_type_de_champs_repetition.second.libelle }
  let(:text_repetition_value) { "First repetition text" }
  let(:integer_repetition_value) { "42" }
  let(:dossier_link_value) { linked_dossier.id }
  let(:prenom_value) { 'Jean' }
  let(:nom_value) { 'Dupont' }
  let(:genre_value) { 'M.' }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\/#{siret_value}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))

    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siret_value[0..8]}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'))
    allow(FranceConnectService).to receive(:enabled?).and_return(true)
  end

  scenario "the user get the URL of a prefilled orphan brouillon dossier" do
    dossier_url = create_and_prefill_dossier_with_post_request

    expect(dossier_url).to eq(commencer_path(procedure.path, prefill_token: dossier.prefill_token))
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
          click_on 'Poursuivre mon dossier prérempli'
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
            click_on 'Poursuivre mon dossier prérempli'
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

            expect(page).to have_content('Vous avez un dossier prérempli')
            click_on 'Poursuivre mon dossier prérempli'
          end
        end
      end

      context 'when the user signs up with FranceConnect' do
        it_behaves_like "the user has got a prefilled dossier, owned by themselves" do
          let(:user) { User.last }

          before do
            state, nonce = ['state', 'nonce']

            allow(FranceConnectService).to receive(:authorization_uri)
              .and_return([
                france_connect_callback_path(code: "c0d3", state:),
                state, nonce
              ])

            allow(FranceConnectService).to receive(:retrieve_user_informations).and_return([build(:france_connect_information), 'id_token'])

            page.find('.fr-connect').click
            expect(page).to have_content("Choisissez votre adresse électronique de contact pour finaliser votre connexion")

            find('label', text: /Oui, utiliser .* comme adresse électronique de contact/).click

            click_on 'Valider'
            expect(page).to have_content('Vous avez un dossier prérempli')
            find('.fr-btn.fr-mb-2w', text: 'Poursuivre mon dossier prérempli', wait: 10).click
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
        "champ_#{type_de_champ_text.to_typed_id_for_query}" => text_value,
        "champ_#{type_de_champ_phone.to_typed_id_for_query}" => phone_value,
        "champ_#{type_de_champ_siret.to_typed_id_for_query}" => siret_value,
        "champ_#{type_de_champ_repetition.to_typed_id_for_query}" => [
          {
            "champ_#{sub_type_de_champs_repetition.first.to_typed_id_for_query}": text_repetition_value,
            "champ_#{sub_type_de_champs_repetition.second.to_typed_id_for_query}": integer_repetition_value,
          }
        ],
        "champ_#{type_de_champ_datetime.to_typed_id_for_query}" => datetime_value,
        "champ_#{type_de_champ_multiple_drop_down_list.to_typed_id_for_query}" => multiple_drop_down_list_values,
        "champ_#{type_de_champ_epci.to_typed_id_for_query}" => epci_value,
        "champ_#{type_de_champ_dossier_link.to_typed_id_for_query}" => dossier_link_value,
        "champ_#{type_de_champ_commune.to_typed_id_for_query}" => commune_value,
        "champ_#{type_de_champ_address.to_typed_id_for_query}" => address_value,
        "identite_prenom" => prenom_value,
        "identite_nom" => nom_value,
        "identite_genre" => genre_value,
      }.to_json
    JSON.parse(session.response.body)["dossier_url"].gsub("http://www.example.com", "")
  end
end
