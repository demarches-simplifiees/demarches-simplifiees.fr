describe 'dropdown list with other option activated', js: true do
  let(:password) { SECURE_PASSWORD }
  let!(:user) { create(:user, password: password) }

  let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :drop_down_list, libelle: 'simple dropdown other', options: options + [:other] }]) }

  let(:user_dossier) { user.dossiers.first }

  before do
    login_as(user, scope: :user)
    visit "/commencer/#{procedure.path}?locale=fr"
    click_on 'Commencer la démarche'
  end
  context 'with radios' do
    let(:options) do
      [
        '--Primary 1--',
        'Secondary 1.1',
        'Secondary 1.2'
      ]
    end

    scenario 'Select other option and the other input hidden must appear' do
      fill_individual
      choose I18n.t('shared.champs.drop_down_list.other'), allow_label_click: true
      expect(page).to have_selector('.drop_down_other', visible: true)
    end

    scenario "Getting back from other save the new option" do
      fill_individual
      choose I18n.t('shared.champs.drop_down_list.other'), allow_label_click: true
      fill_in(I18n.t('shared.champs.drop_down_list.other_label'), with: "My choice")

      wait_until { user_dossier.champs_public.first.value == "My choice" }
      expect(user_dossier.champs_public.first.value).to eq("My choice")

      choose "Secondary 1.1"

      wait_until { user_dossier.champs_public.first.value == "Secondary 1.1" }
      expect(user_dossier.champs_public.first.value).to eq("Secondary 1.1")
    end
  end

  context 'with select' do
    let(:options) do
      [
        '--Primary 1--',
        'Secondary 1.1',
        'Secondary 1.2',
        'Secondary 1.3',
        'Secondary 1.4',
        'Secondary 1.5',
        'Secondary 1.6'
      ]
    end

    scenario 'with a select and other, selecting a value save it (avoid hidden other_value to be sent)' do
      fill_individual

      expect(page).not_to have_selector(".drop_down_other input")
      select(I18n.t('shared.champs.drop_down_list.other'))
      find(".drop_down_other input", visible: true)

      select("Secondary 1.2")
      expect(page).to have_selector(".autosave-status.succeeded", visible: true)

      wait_until { user_dossier.champs_public.first.value == "Secondary 1.2" }
      expect(user_dossier.champs_public.first.value).to eq("Secondary 1.2")
    end
  end

  private

  def fill_individual
    find('label', text: 'Monsieur').click
    within('.individual-infos') do
      fill_in('Prénom', with: 'prenom')
      fill_in('Nom', with: 'nom')
    end
    within "#identite-form" do
      click_on 'Continuer'
    end
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
    # pf: wait for connected stimulus controller
    expect(page).to have_css('[data-controller="autosave"][data-controller-connected="true"]')
  end
end
