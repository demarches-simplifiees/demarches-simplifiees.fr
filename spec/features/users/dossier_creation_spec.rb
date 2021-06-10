feature 'Creating a new dossier:' do
  let(:user)  { create(:user) }
  let(:siret) { '41816609600051' }
  let(:siren) { siret[0...9] }

  context 'when the user is already signed in' do
    before do
      login_as user, scope: :user
    end

    context 'when the procedure has identification by individual' do
      let(:procedure) { create(:procedure, :published, :for_individual, :with_service, ask_birthday: ask_birthday) }
      let(:ask_birthday) { false }
      let(:expected_birthday) { nil }

      before do
        visit commencer_path(path: procedure.path)
        click_on 'Commencer la démarche'

        expect(page).to have_current_path identite_dossier_path(user.reload.dossiers.last)
        expect(page).to have_procedure_description(procedure)

        choose 'Monsieur'
        fill_in 'individual_nom',    with: 'Nom'
        fill_in 'individual_prenom', with: 'Prenom'
      end

      shared_examples 'the user can create a new draft' do
        it do
          click_button('Continuer')

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

    context 'when the procedure has identification by individual' do
      let(:procedure) do
        create(:procedure, :published, :for_individual, :with_service,
               api_particulier_scopes: scopes, api_particulier_sources: sources)
      end

      context 'when API Particulier is enabled' do
        before do
          Flipper.enable(:api_particulier)
          visit commencer_path(path: procedure.path)
          click_on 'Commencer la démarche'

          expect(page).to have_current_path identite_dossier_path(user.reload.dossiers.last)
          expect(page).to have_procedure_description(procedure)
        end

        context "when DGFIP scopes are present" do
          let(:scopes) { APIParticulier::Types::DGFIP_SCOPES }

          context "but without selected sources" do
            let(:sources) { nil }

            it "wont display DGFIP fields only" do
              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("Identifiant pôle emploi")
              expect(page).not_to have_content("INE étudiant")
            end
          end

          context "and some sources are selected" do
            let(:sources) do
              {
                dgfip: {
                  foyer_fiscal: { annee: 1, adresse: 0 },
                  avis_imposition: {
                    declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 }
                  }
                }
              }
            end

            it "must display DGFIP fields only" do
              expect(page).to have_content("Numéro fiscal")
              expect(page).to have_content("Référence de l'avis fiscal")

              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("Identifiant pôle emploi")
              expect(page).not_to have_content("INE étudiant")
            end
          end
        end

        context "when CAF scopes are present" do
          let(:scopes) { APIParticulier::Types::CAF_SCOPES }

          context "but without selected sources" do
            let(:sources) { nil }

            it "wont display CAF fields only" do
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Identifiant pôle emploi")
              expect(page).not_to have_content("INE étudiant")
            end
          end

          context "and some sources are selected" do
            let(:sources) do
              {
                caf: {
                  allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
                  quotient_familial: 1
                }
              }
            end

            it "must display CAF fields only" do
              expect(page).to have_content("Numéro d'allocataire CAF")
              expect(page).to have_content("Code postal")

              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Identifiant pôle emploi")
              expect(page).not_to have_content("INE étudiant")
            end
          end
        end

        context "when Pole Emploi scopes are present" do
          let(:scopes) { APIParticulier::Types::POLE_EMPLOI_SCOPES }

          context "but without selected sources" do
            let(:sources) { nil }

            it "must display Pole Emploi fields only" do
              expect(page).not_to have_content("Identifiant pôle emploi")
              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("INE étudiant")
            end
          end

          context "and some sources are selected" do
            let(:sources) do
              {
                pole_emploi: { situation: { email: 1, nom: 0 } }
              }
            end

            it "must display Pole Emploi fields only" do
              expect(page).to have_content("Identifiant pôle emploi")

              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("INE étudiant")
            end
          end
        end

        context "when MESRI scopes are present" do
          let(:scopes) { APIParticulier::Types::ETUDIANT_SCOPES }

          context "but without selected sources" do
            let(:sources) { nil }

            it "wont display MESRI fields only" do
              expect(page).not_to have_content("INE étudiant")
              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("Identifiant pôle emploi")
            end
          end

          context "and some sources are selected" do
            let(:sources) do
              {
                mesri: {
                  statut_etudiant: { inscriptions: { etablissement: { nom: 1, uai: 0 } } }
                }
              }
            end

            it "must display MESRI fields only" do
              expect(page).to have_content("INE étudiant")

              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("Identifiant pôle emploi")
            end
          end
        end

        context "when CAF & MESRI scopes are present" do
          let(:scopes) { APIParticulier::Types::ETUDIANT_SCOPES + APIParticulier::Types::CAF_SCOPES }

          context "but without selected sources" do
            let(:sources) { nil }

            it "wont display CAF & MESRI fields" do
              expect(page).not_to have_content("Numéro d'allocataire CAF")
              expect(page).not_to have_content("Code postal")
              expect(page).not_to have_content("INE étudiant")
              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Identifiant pôle emploi")
            end
          end

          context "and only some CAF sources are selected" do
            let(:sources) do
              {
                caf: {
                  allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
                  quotient_familial: 1
                },
                mesri: {
                  statut_etudiant: { inscriptions: { etablissement: { nom: 0, uai: 0 } } }
                }
              }
            end

            it "must display CAF fields" do
              expect(page).to have_content("Numéro d'allocataire CAF")
              expect(page).to have_content("Code postal")

              expect(page).not_to have_content("INE étudiant")
              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Identifiant pôle emploi")
            end
          end

          context "and some sources are selected" do
            let(:sources) do
              {
                caf: {
                  allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
                  quotient_familial: 1
                },
                mesri: {
                  statut_etudiant: { inscriptions: { etablissement: { nom: 1, uai: 0 } } }
                }
              }
            end

            it "must display CAF & MESRI fields" do
              expect(page).to have_content("Numéro d'allocataire CAF")
              expect(page).to have_content("Code postal")
              expect(page).to have_content("INE étudiant")

              expect(page).not_to have_content("Numéro fiscal")
              expect(page).not_to have_content("Référence de l'avis fiscal")
              expect(page).not_to have_content("Identifiant pôle emploi")
            end
          end
        end
      end

      context 'when API Particulier is disabled' do
        before do
          Flipper.disable(:api_particulier)
          visit commencer_path(path: procedure.path)
          click_on 'Commencer la démarche'

          expect(page).to have_current_path identite_dossier_path(user.reload.dossiers.last)
          expect(page).to have_procedure_description(procedure)
        end

        let(:scopes) { APIParticulier::Types::SCOPES }

        let(:sources) do
          {
            dgfip: {
              foyer_fiscal: { annee: 1, adresse: 0 },
              avis_imposition: {
                declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 }
              }
            },
            caf: { quotient_familial: 1 },
            pole_emploi: { situation: { email: 1, nom: 0 } },
            mesri: {
              statut_etudiant: { inscriptions: { etablissement: { nom: 1, uai: 0 } } }
            }
          }
        end

        it "wont display any API Partucilier fields" do
          expect(page).not_to have_content("Numéro fiscal")
          expect(page).not_to have_content("Référence de l'avis fiscal")
          expect(page).not_to have_content("Numéro d'allocataire CAF")
          expect(page).not_to have_content("Code postal")
          expect(page).not_to have_content("Identifiant pôle emploi")
          expect(page).not_to have_content("INE étudiant")
        end
      end
    end

    context 'when identifying through SIRET' do
      let(:procedure) { create(:procedure, :published, :with_service, :with_type_de_champ) }
      let(:dossier) { procedure.dossiers.last }

      before do
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'))
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/#{siret}/)
          .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/exercices.json'))
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/#{siret}/)
          .to_return(status: 404, body: '')
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/effectifs_mensuels_acoss_covid\/2020\/02\/entreprise\/#{siren}/)
          .to_return(status: 404, body: '')
        stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/effectifs_annuels_acoss_covid\/#{siren}/)
          .to_return(status: 404, body: '')
        allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return([])
        allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      end
      before { Timecop.freeze(Time.zone.local(2020, 3, 14)) }
      after { Timecop.return }

      scenario 'the user can enter the SIRET of its etablissement and create a new draft' do
        visit commencer_path(path: procedure.path)
        click_on 'Commencer la démarche'

        expect(page).to have_current_path siret_dossier_path(dossier)
        expect(page).to have_procedure_description(procedure)

        fill_in 'Numéro SIRET', with: siret
        click_on 'Valider'

        expect(page).to have_current_path(etablissement_dossier_path(dossier))
        expect(page).to have_content('OCTO TECHNOLOGY')
        click_on 'Continuer avec ces informations'

        expect(page).to have_current_path(brouillon_dossier_path(dossier))
      end

      scenario 'the user is notified when its SIRET is invalid' do
        visit commencer_path(path: procedure.path)
        click_on 'Commencer la démarche'

        expect(page).to have_current_path(siret_dossier_path(dossier))
        expect(page).to have_procedure_description(procedure)

        fill_in 'Numéro SIRET', with: '0000'
        click_on 'Valider'

        expect(page).to have_current_path(siret_dossier_path(dossier))
        expect(page).to have_content('Le numéro SIRET doit comporter 14 chiffres')
        expect(page).to have_field('Numéro SIRET', with: '0000')
      end
    end
  end

  context 'when the user is not signed in' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published) }
    scenario 'the user is an instructeur with untrusted device' do
      visit commencer_path(path: procedure.path)
      click_on "J’ai déjà un compte"
      sign_in_with(instructeur.email, instructeur.user.password, true)

      expect(page).to have_current_path(commencer_path(path: procedure.path))
    end
  end
end
