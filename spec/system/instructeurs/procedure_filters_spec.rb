describe "procedure filters" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text }, { type: :departements }, { type: :regions }, { type: :drop_down_list }], instructeurs: [instructeur]) }
  let!(:type_de_champ) { procedure.active_revision.types_de_champ_public.first }
  let!(:new_unfollow_dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }
  let!(:champ) { Champ.find_by(type_de_champ_id: type_de_champ.id, dossier_id: new_unfollow_dossier.id) }
  let!(:new_unfollow_dossier_2) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }
  let!(:champ_2) { Champ.find_by(type_de_champ_id: type_de_champ.id, dossier_id: new_unfollow_dossier_2.id) }

  before do
    champ.update(value: "Mon champ rempli")
    champ_2.update(value: "Mon autre champ rempli différemment")
    login_as(instructeur.user, scope: :user)
    visit instructeur_procedure_path(procedure)
  end

  scenario "should display demandeur by default" do
    within ".dossiers-table" do
      expect(page).to have_link("Demandeur")
      expect(page).to have_link(new_unfollow_dossier.user.email)
    end
  end

  scenario "should display sva by default if procedure has sva enabled" do
    procedure.update!(sva_svr: SVASVRConfiguration.new(decision: :sva).attributes)
    visit instructeur_procedure_path(procedure)
    within ".dossiers-table" do
      expect(page).to have_link("Date décision SVA")
      expect(page).to have_link(new_unfollow_dossier.user.email)
    end
  end

  scenario "should list all dossiers" do
    within ".dossiers-table" do
      expect(page).to have_link(new_unfollow_dossier.id.to_s)
      expect(page).to have_link(new_unfollow_dossier.user.email)

      expect(page).to have_link(new_unfollow_dossier_2.id.to_s)
      expect(page).to have_link(new_unfollow_dossier_2.user.email)
    end
  end

  scenario "should add be able to add created_at column", js: true do
    add_column("Créé le")
    within ".dossiers-table" do
      expect(page).to have_link("Créé le")
      expect(page).to have_link(new_unfollow_dossier.created_at.strftime('%d/%m/%Y'))
    end
  end

  scenario "should add be able to add and remove custom type_de_champ column", js: true do
    add_column(type_de_champ.libelle)
    within ".dossiers-table" do
      expect(page).to have_link(type_de_champ.libelle)
      expect(page).to have_link(champ.value)
    end

    remove_column(type_de_champ.libelle)
    within ".dossiers-table" do
      expect(page).not_to have_link(type_de_champ.libelle)
      expect(page).not_to have_link(champ.value)
    end
  end

  scenario "should be able to add and remove filter", js: true do
    add_filter(type_de_champ.libelle, champ.value)

    expect(page).to have_content("#{type_de_champ.libelle} : #{champ.value}")

    within ".dossiers-table" do
      expect(page).to have_link(new_unfollow_dossier.id.to_s, exact: true)
      expect(page).to have_link(new_unfollow_dossier.user.email)

      expect(page).not_to have_link(new_unfollow_dossier_2.id.to_s, exact: true)
      expect(page).not_to have_link(new_unfollow_dossier_2.user.email)
    end

    remove_filter(champ.value)

    within ".dossiers-table" do
      expect(page).to have_link(new_unfollow_dossier.id.to_s)
      expect(page).to have_link(new_unfollow_dossier.user.email)

      expect(page).to have_link(new_unfollow_dossier_2.id.to_s)
      expect(page).to have_link(new_unfollow_dossier_2.user.email)
    end
  end

  scenario "should be able to user custom fiters", js: true do
    # use date filter
    add_filter("En construction le", "10/10/2010", type: :date)

    # use statut dropdown filter
    add_filter('Statut', 'En construction', type: :enum)

    # use choice dropdown filter
    add_filter('Choix unique', 'val1', type: :enum)
  end

  describe 'with a vcr cached cassette' do
    scenario "should be able to find by departements with custom enum lookup", js: true do
      departement_champ = new_unfollow_dossier.champs.find(&:departement?)
      departement_champ.update!(value: 'Oise', external_id: '60')
      departement_champ.reload
      champ_select_value = "#{departement_champ.external_id} – #{departement_champ.value}"

      add_filter(departement_champ.libelle, champ_select_value, type: :enum)
      expect(page).to have_link(new_unfollow_dossier.id.to_s)
    end

    scenario "should be able to find by region with custom enum lookup", js: true do
      region_champ = new_unfollow_dossier.champs.find(&:region?)
      region_champ.update!(value: 'Bretagne', external_id: '53')
      region_champ.reload

      add_filter(region_champ.libelle, region_champ.value, type: :enum)
      expect(page).to have_link(new_unfollow_dossier.id.to_s)
    end
  end

  scenario "should be able to add and remove two filters for the same field", js: true do
    add_filter(type_de_champ.libelle, champ.value)
    add_filter(type_de_champ.libelle, champ_2.value)
    add_filter('Groupe instructeur', procedure.groupe_instructeurs.first.label, type: :enum)

    within ".dossiers-table" do
      expect(page).to have_link(new_unfollow_dossier.id.to_s, exact: true)
      expect(page).to have_link(new_unfollow_dossier.user.email)

      expect(page).to have_link(new_unfollow_dossier_2.id.to_s, exact: true)
      expect(page).to have_link(new_unfollow_dossier_2.user.email)
    end

    remove_filter(champ.value)

    within ".dossiers-table" do
      expect(page).not_to have_link(new_unfollow_dossier.id.to_s, exact: true)
      expect(page).not_to have_link(new_unfollow_dossier.user.email)

      expect(page).to have_link(new_unfollow_dossier_2.id.to_s, exact: true)
      expect(page).to have_link(new_unfollow_dossier_2.user.email)
    end

    remove_filter(champ_2.value)

    within ".dossiers-table" do
      expect(page).to have_link(new_unfollow_dossier.id.to_s, exact: true)
      expect(page).to have_link(new_unfollow_dossier.user.email)
      expect(page).to have_link(new_unfollow_dossier_2.id.to_s, exact: true)
      expect(page).to have_link(new_unfollow_dossier_2.user.email)
    end
  end

  def add_filter(column_name, filter_value, type: :text)
    click_on 'Sélectionner un filtre'
    wait_until { all("#search-filter").size == 1 }
    find('#search-filter + button', wait: 5).click
    find('.fr-menu__item', text: column_name, wait: 5).click
    case type
    when :text
      fill_in "Valeur", with: filter_value
    when :date
      find("input#value[type=date]", visible: true)
      fill_in "Valeur", with: filter_value
    when :enum
      find("select#value", visible: false)
      select filter_value, from: "Valeur"
    end
    click_button "Ajouter le filtre"
    expect(page).to have_no_css("#search-filter", visible: true)
  end

  def remove_filter(filter_value)
    click_link text: filter_value
  end

  def add_column(column_name)
    click_on 'Personnaliser'
    select_combobox('Colonne à afficher', column_name)
    click_button "Enregistrer"
  end

  def remove_column(column_name)
    click_on 'Personnaliser'
    within '.fr-tag-list' do
      find('.fr-tag', text: column_name).find('button').click
    end
    click_button "Enregistrer"
  end
end
