require 'spec_helper'

feature 'Creating a new dossier:' do
  let(:user)  { create(:user) }
  let(:siret) { '40307130100044' }
  let(:siren) { siret[0...9] }

  context 'when the user is already signed in' do
    before do
      login_as user, scope: :user
    end

    context 'when the procedure has identification by individual' do
      let(:procedure) { create(:procedure, :published, :for_individual, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative, ask_birthday: ask_birthday) }
      let(:ask_birthday) { false }
      let(:expected_birthday) { nil }

      before do
        visit commencer_path(path: procedure.path)
        fill_in 'individual_nom',    with: 'Nom'
        fill_in 'individual_prenom', with: 'Prenom'
      end

      shared_examples 'the user can create a new draft' do
        it do
          click_button('Continuer')

          expect(page).to have_current_path(users_dossier_carte_path(procedure.dossiers.last.id))
          click_button('Etape suivante')

          expect(page).to have_current_path(brouillon_dossier_path(procedure.dossiers.last))

          expect(user.dossiers.first.individual.birthdate).to eq(expected_birthday)
        end
      end

      context 'when the birthday is asked' do
        let(:ask_birthday) { true }
        let(:expected_birthday) { Date.new(1987, 10, 14) }

        before do
          fill_in 'individual_birthdate', with: birthday_format
        end

        context 'when the browser supports `type=date` input fields' do
          let(:birthday_format) { '1987-10-14' }
          it_behaves_like 'the user can create a new draft'
        end

        context 'when the browser does not support `type=date` input fields' do
          let(:birthday_format) { '1987-10-14' }
          it_behaves_like 'the user can create a new draft'
        end
      end

      context 'when the birthday is not asked' do
        let(:ask_birthday) { false }
        let(:expected_birthday) { nil }
        it_behaves_like 'the user can create a new draft'
      end
    end

    context 'when identifying through SIRET' do
      let(:procedure) { create(:procedure, :published, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }
      let(:dossier) { procedure.dossiers.last }

      before do
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'))
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/#{siret}?.*token=/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/exercices.json'))
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/#{siret}?.*token=/)
          .to_return(status: 404, body: '')
      end

      scenario 'the user can enter the SIRET of its etablissement and create a new draft', vcr: { cassette_name: 'api_adresse_search_paris_3' }, js: true do
        visit commencer_path(path: procedure.path)
        expect(page).to have_current_path(siret_dossier_path(dossier))

        fill_in 'Numéro SIRET', with: siret
        click_on 'Valider'

        expect(page).to have_current_path(etablissement_dossier_path(dossier))
        expect(page).to have_content('OCTO-TECHNOLOGY')
        click_on 'Continuer avec ces informations'

        expect(page).to have_current_path(users_dossier_carte_path(dossier))
        click_button('Etape suivante')

        expect(page).to have_current_path(brouillon_dossier_path(dossier))
      end

      scenario 'the user is notified when its SIRET is invalid' do
        visit commencer_path(path: procedure.path)
        expect(page).to have_current_path(siret_dossier_path(dossier))

        fill_in 'Numéro SIRET', with: '0000'
        click_on 'Valider'

        expect(page).to have_current_path(siret_dossier_path(dossier))
        expect(page).to have_content('Le numéro SIRET doit comporter 14 chiffres')
        expect(page).to have_field('Numéro SIRET', with: '0000')
      end
    end
  end
end
