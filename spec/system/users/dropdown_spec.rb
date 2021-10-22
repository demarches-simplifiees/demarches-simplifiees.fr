describe 'dropdown list with other option activated' do
  let(:password) { 'my-s3cure-p4ssword' }
  let!(:user) { create(:user, password: password) }

  let(:list_items) do
    <<~END_OF_LIST
      --Primary 1--
      Secondary 1.1
      Secondary 1.2
    END_OF_LIST
  end

  let(:type_de_champ) { build(:type_de_champ_drop_down_list, libelle: 'simple dropdown other', drop_down_list_value: list_items, drop_down_other: true) }

  let(:procedure) do
    create(:procedure, :published, :for_individual, types_de_champ: [type_de_champ])
  end

  let(:user_dossier) { user.dossiers.first }

  before do
    login_as(user, scope: :user)
    visit "/commencer/#{procedure.path}"
    click_on 'Commencer la démarche'
  end

  scenario 'Select other option and the other input hidden must appear', js: true do
    fill_individual

    find('.radios').find('label:last-child').find('input').select_option
    expect(page).to have_selector('.drop_down_other', visible: true)
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
