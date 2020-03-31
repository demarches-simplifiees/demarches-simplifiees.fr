feature "procedure filters" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, instructeurs: [instructeur]) }
  let!(:type_de_champ) { procedure.types_de_champ.first }
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

  scenario "should be able to add and remove two filters for the same field", js: true do
    add_filter(type_de_champ.libelle, champ.value)
    add_filter(type_de_champ.libelle, champ_2.value)

    expect(page).to have_content("#{type_de_champ.libelle} : #{champ.value}")

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
    find(:xpath, "(//span[contains(@class, 'filter')]/a[contains(@href, '#{CGI.escape(filter_value)}')])[1]").click
  end

  def add_filter(column_name, filter_value)
    click_on 'Filtrer'
    select column_name, from: "Colonne"
    fill_in "Valeur", with: filter_value
    click_button "Ajouter le filtre"
  end

  def add_column(column_name)
    click_on 'Personnaliser'
    find("span.select2-container").click
    find(:xpath, "//li[text()='#{column_name}']").click
    click_button "Enregistrer"
  end

  def remove_column(column_name)
    click_on 'Personnaliser'
    find(:xpath, "//li[contains(@title, '#{column_name}')]/span[contains(text(), '×')]").click
    find(:xpath, "//form[contains(@class, 'columns-form')]//span[contains(@class, 'select2-container')]").click
    click_button "Enregistrer"
  end
end
