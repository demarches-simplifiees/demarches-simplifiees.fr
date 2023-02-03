describe 'Getting help:' do
  scenario 'a Help button is visible on public pages' do
    visit '/'
    within('.fr-header') do
      expect(page).to have_help_button
    end
  end

  context 'on pages related to a procedure' do
    let(:procedure) { create(:procedure, :published, :with_service) }

    scenario 'a Help menu provides administration contacts and a link to the FAQ' do
      visit commencer_path(path: procedure.path)

      within('.fr-header') do
        expect(page).to have_help_menu
      end

      within('.help-dropdown') do
        expect(page).to have_content(procedure.service.email)
        expect(page).to have_content(procedure.service.telephone)
        expect(page).to have_link(nil, href: FAQ_URL)
      end
    end
  end

  context 'as a signed-in user' do
    let(:user) { create(:user) }
    let(:procedure) { create(:procedure, :with_service) }

    before do
      login_as user, scope: :user
    end

    scenario 'a Help button is visible on signed-in pages' do
      visit dossiers_path
      within('.fr-header') do
        expect(page).to have_help_button
      end
    end

    context 'on a page related to a draft dossier' do
      let(:dossier) { create(:dossier, user: user, procedure: procedure) }

      scenario 'a Help menu provides administration contacts and a link to the FAQ' do
        visit dossier_path(dossier)

        within('.fr-header') do
          expect(page).to have_help_menu
        end

        within('.help-dropdown') do
          expect(page).to have_content(dossier.procedure.service.email)
          expect(page).to have_content(dossier.procedure.service.telephone)
          expect(page).to have_link(nil, href: FAQ_URL)
        end
      end
    end

    context 'on a page related to a submitted dossier' do
      let(:dossier) { create(:dossier, :en_construction, user: user, procedure: procedure) }

      scenario 'a Help menu provides links to the Messagerie and to the FAQ' do
        visit dossier_path(dossier)

        within('.fr-header') do
          expect(page).to have_help_menu
        end

        within('.help-dropdown') do
          expect(page).to have_link(nil, href: messagerie_dossier_path(dossier))
          expect(page).to have_link(nil, href: FAQ_URL)
        end
      end
    end
  end

  context 'as a instructeur' do
    let(:instructeur) { create(:instructeur) }

    before do
      login_as instructeur.user, scope: :user
    end

    scenario 'a Help menu is visible on signed-in pages' do
      visit instructeur_procedures_path
      within('.fr-header') do
        expect(page).to have_help_menu
      end
    end
  end

  def have_help_button
    have_link('Aide', href: FAQ_URL)
  end

  def have_help_menu
    have_selector('.help-dropdown')
  end
end
