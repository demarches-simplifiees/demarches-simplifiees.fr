describe 'dropdown list with other option activated', js: true do
  let(:password) { 'my-s3cure-p4ssword' }
  let!(:user) { create(:user, password: password) }

  let(:type_de_champ) { build(:type_de_champ_drop_down_list, libelle: 'simple dropdown other', drop_down_list_value: list_items, drop_down_other: true) }

  let(:procedure) do
    create(:procedure, :published, :for_individual, types_de_champ: [type_de_champ])
  end

  let(:user_dossier) { user.dossiers.first }

  before do
    login_as(user, scope: :user)
    visit "/commencer/#{procedure.path}?locale=fr"
    click_on 'Commencer la démarche'
  end
  context 'with radios' do
    let(:list_items) do
      <<~END_OF_LIST
        --Primary 1--
        Secondary 1.1
        Secondary 1.2
      END_OF_LIST
    end

    scenario 'Select other option and the other input hidden must appear', js: true do
      fill_individual

      find('.radios').find('label:last-child').find('input').select_option
      expect(page).to have_selector('.drop_down_other', visible: true)
    end
  end

  context 'with select' do
    let(:list_items) do
      <<~END_OF_LIST
        --Primary 1--
        Secondary 1.1
        Secondary 1.2
        Secondary 1.3
        Secondary 1.4
        Secondary 1.5
        Secondary 1.6
      END_OF_LIST
    end

    scenario 'with a select and other, selecting a value save it (avoid hidden other_value to be sent)' do
      fill_individual

      find(".drop_down_other input", visible: false)
      select("Autre")
      find(".drop_down_other input", visible: true)

      select("Secondary 1.2")
      expect(page).to have_selector(".autosave-status.succeeded", visible: true)
      expect(user_dossier.champs.first.value).to eq("Secondary 1.2")
    end
  end

  private

  def fill_individual
    choose 'Monsieur'
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    click_on 'Continuer'
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
  end
end
