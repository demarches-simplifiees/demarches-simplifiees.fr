describe "procedure filters" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, :with_departement, :with_region, :with_drop_down_list, instructeurs: [instructeur]) }
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

  scenario "should add be able to add created_at column", js: true, retry: 3 do
    add_column("Créé le")
    within ".dossiers-table" do
      expect(page).to have_link("Créé le")
      expect(page).to have_link(new_unfollow_dossier.created_at.strftime('%d/%m/%Y'))
    end
  end

  scenario "should add be able to add and remove custom type_de_champ column", js: true, retry: 3 do
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

  scenario "should be able to add and remove filter", js: true, retry: 3 do
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

  scenario "should be able to user custom fiters", js: true, retry: 3 do
    # use date filter
    click_on 'Sélectionner un filtre'
    select "En construction le", from: "Colonne"
    find("input#value[type=date]", visible: true)
    fill_in "Valeur", with: "10/10/2010"
    click_button "Ajouter le filtre"
    expect(page).to have_no_css("select#field", visible: true)

    # use statut dropdown filter
    click_on 'Sélectionner un filtre'
    select "Statut", from: "Colonne"
    find("select#value", visible: false)
    select 'En construction', from: "Valeur"
    click_button "Ajouter le filtre"
    expect(page).to have_no_css("select#field", visible: true)

    # use choice dropdown filter
    click_on 'Sélectionner un filtre'
    select "Choix unique", from: "Colonne"
    find("select#value", visible: false)
    select 'val1', from: "Valeur"
    click_button "Ajouter le filtre"
  end

  describe 'with a vcr cached cassette' do
    scenario "should be able to find by departements with custom enum lookup", js: true, retry: 3 do
      departement_champ = new_unfollow_dossier.champs.find(&:departement?)
      departement_champ.update!(value: 'Oise', external_id: '60')
      departement_champ.reload
      champ_select_value = "#{departement_champ.external_id} – #{departement_champ.value}"

      click_on 'Sélectionner un filtre'
      select departement_champ.libelle, from: "Colonne"
      find("select#value", visible: true)
      select champ_select_value, from: "Valeur"
      click_button "Ajouter le filtre"
      find("select#value", visible: false) # w8 for filter to be applied
      expect(page).to have_link(new_unfollow_dossier.id.to_s)
    end

    scenario "should be able to find by region with custom enum lookup", js: true, retry: 3 do
      region_champ = new_unfollow_dossier.champs.find(&:region?)
      region_champ.update!(value: 'Bretagne', external_id: '53')
      region_champ.reload

      click_on 'Sélectionner un filtre'
      select region_champ.libelle, from: "Colonne"
      find("select#value", visible: true)
      select region_champ.value, from: "Valeur"
      click_button "Ajouter le filtre"
      find("select#value", visible: false) # w8 for filter to be applied
      expect(page).to have_link(new_unfollow_dossier.id.to_s)
    end
  end

  scenario "should be able to add and remove two filters for the same field", js: true, retry: 3 do
    add_filter(type_de_champ.libelle, champ.value)
    add_filter(type_de_champ.libelle, champ_2.value)
    add_enum_filter('Groupe instructeur', procedure.groupe_instructeurs.first.label)

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

  def remove_filter(filter_value)
    click_link text: filter_value
  end

  def add_filter(column_name, filter_value)
    click_on 'Sélectionner un filtre'
    select column_name, from: "Colonne"
    fill_in "Valeur", with: filter_value
    click_button "Ajouter le filtre"
    expect(page).to have_no_css("select#field", visible: true)
  end

  def add_enum_filter(column_name, filter_value)
    click_on 'Sélectionner un filtre'
    select column_name, from: "Colonne"
    select filter_value, from: "Valeur"
    click_button "Ajouter le filtre"
    expect(page).to have_no_css("select#field", visible: true)
  end

  def add_column(column_name)
    click_on 'Personnaliser'
    select_combobox('Colonne à afficher', column_name, column_name, check: false)
    click_button "Enregistrer"
  end

  def remove_column(column_name)
    click_on 'Personnaliser'
    click_button column_name
    find("body").native.send_key("Escape")
    click_button "Enregistrer"
  end
end
