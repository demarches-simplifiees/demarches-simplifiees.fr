describe 'Prefilling a dossier (with a GET request):' do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  let(:password) { 'my-s3cure-p4ssword' }

  let(:procedure) { create(:procedure, :published, opendata: true) }
  let(:dossier) { procedure.dossiers.last }

  let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
  let(:type_de_champ_phone) { create(:type_de_champ_phone, procedure: procedure) }
  let(:type_de_champ_datetime) { create(:type_de_champ_datetime, procedure: procedure) }
  let(:type_de_champ_epci) { create(:type_de_champ_epci, procedure: procedure) }
  let(:type_de_champ_repetition) { create(:type_de_champ_repetition, :with_types_de_champ, procedure: procedure) }
  let(:text_value) { "My Neighbor Totoro is the best movie ever" }
  let(:phone_value) { "invalid phone value" }
  let(:datetime_value) { "2023-02-01T10:32" }
  let(:epci_value) { ['01', '200029999'] }
  let(:sub_type_de_champs_repetition) { type_de_champ_repetition.active_revision_type_de_champ.revision_types_de_champ.map(&:type_de_champ) }
  let(:text_repetition_libelle) { sub_type_de_champs_repetition.first.libelle }
  let(:integer_repetition_libelle) { sub_type_de_champs_repetition.second.libelle }
  let(:text_repetition_value) { "First repetition text" }
  let(:integer_repetition_value) { "42" }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear

    VCR.insert_cassette('api_geo_departements')
    VCR.insert_cassette('api_geo_epcis')
  end

  after do
    VCR.eject_cassette('api_geo_departements')
    VCR.eject_cassette('api_geo_epcis')
  end

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
          "champ_#{type_de_champ_repetition.to_typed_id}" => [
            "{
              \"#{sub_type_de_champs_repetition.first.to_typed_id}\": \"#{text_repetition_value}\",
              \"#{sub_type_de_champs_repetition.second.to_typed_id}\": \"#{integer_repetition_value}\"
            }"
          ],
          "champ_#{type_de_champ_datetime.to_typed_id}" => datetime_value,
          "champ_#{type_de_champ_epci.to_typed_id}" => epci_value
        )

        click_on "Poursuivre mon dossier prérempli"
      end
    end
  end

  context 'when unauthenticated' do
    before do
      visit commencer_path(
        path: procedure.path,
        "champ_#{type_de_champ_text.to_typed_id}" => text_value,
        "champ_#{type_de_champ_phone.to_typed_id}" => phone_value,
        "champ_#{type_de_champ_repetition.to_typed_id}" => [
          "{
            \"#{sub_type_de_champs_repetition.first.to_typed_id}\": \"#{text_repetition_value}\",
            \"#{sub_type_de_champs_repetition.second.to_typed_id}\": \"#{integer_repetition_value}\"
          }"
        ],
        "champ_#{type_de_champ_datetime.to_typed_id}" => datetime_value,
        "champ_#{type_de_champ_epci.to_typed_id}" => epci_value
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
