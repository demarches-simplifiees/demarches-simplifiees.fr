require 'system/users/dossier_shared_examples.rb'

describe 'Dossier Inéligibilité', js: true do
  include Logic

  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:, user:) }

  let(:published_revision) { procedure.published_revision }
  let(:first_tdc) { published_revision.types_de_champ.first }
  let(:second_tdc) { published_revision.types_de_champ.last }
  let(:ineligibilite_message) { 'sry vous pouvez aps soumettre votre dossier' }
  let(:eligibilite_params) { { ineligibilite_enabled: true, ineligibilite_message: } }

  before do
    published_revision.update(eligibilite_params.merge(ineligibilite_rules:))
    login_as user, scope: :user
  end

  context 'single condition' do
    let(:types_de_champ_public) { [{ type: :yes_no }] }
    let(:ineligibilite_rules) { ds_eq(champ_value(first_tdc.stable_id), constant(true)) }

    scenario 'can submit, can not submit, reload' do
      visit brouillon_dossier_path(dossier)
      # no error while dossier is empty
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: false)
      expect(page).not_to have_content("Vous ne pouvez pas déposer votre dossier")

      # does raise error when dossier is filled with valid condition
      find("label", text: "Non").click
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: false)
      expect(page).not_to have_content("Vous ne pouvez pas déposer votre dossier")

      # raise error when dossier is filled with invalid condition
      find("label", text: "Oui").click
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: true)
      expect(page).to have_content("Vous ne pouvez pas déposer votre dossier")

      # reload page and see error because it was filled
      visit brouillon_dossier_path(dossier)
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: true)
      expect(page).to have_content("Vous ne pouvez pas déposer votre dossier")

      # modal is closable, and we can change our dossier response to be eligible
      within("#modal-eligibilite-rules-dialog") { click_on "Fermer" }
      find("label", text: "Non").click
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: false)

      # it works, yay
      click_on "Déposer le dossier"
      wait_until { dossier.reload.en_construction? == true }
    end
  end

  context 'or condition' do
    let(:types_de_champ_public) { [{ type: :yes_no, libelle: 'l1' }, { type: :drop_down_list, libelle: 'l2', options: ['Paris', 'Marseille'] }] }
    let(:ineligibilite_rules) do
      ds_or([
        ds_eq(champ_value(first_tdc.stable_id), constant(true)),
        ds_eq(champ_value(second_tdc.stable_id), constant('Paris'))
      ])
    end

    scenario 'can submit, can not submit, can edit, etc...' do
      visit brouillon_dossier_path(dossier)
      # no error while dossier is empty
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: false)
      expect(page).not_to have_content("Vous ne pouvez pas déposer votre dossier")

      # only one condition is matches, cannot submit dossier and error message is clear
      within "#champ-#{first_tdc.stable_id}" do
        find("label", text: "Oui").click
      end
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: true)
      expect(page).to have_content("Vous ne pouvez pas déposer votre dossier")
      within("#modal-eligibilite-rules-dialog") { click_on "Fermer" }

      # only one condition does not matches, I can conitnue
      within "#champ-#{first_tdc.stable_id}" do
        find("label", text: "Non").click
      end
      expect(page).to have_selector(:button, text: "Déposer le dossier", disabled: false)

      # Now test dossier modification
      click_on "Déposer le dossier"
      click_on "Accéder à votre dossier"
      click_on "Modifier le dossier"

      # one condition matches, means i'm blocked to send my file.
      within "#champ-#{first_tdc.stable_id}" do
        find("label", text: "Oui").click
      end
      expect(page).to have_selector(:button, text: "Déposer les modifications", disabled: true)
      within("#modal-eligibilite-rules-dialog") { click_on "Fermer" }
      within "#champ-#{first_tdc.stable_id}" do
        find("label", text: "Non").click
      end
      expect(page).to have_selector(:button, text: "Déposer les modifications", disabled: false)

      # second condition matches, means i'm blocked to send my file
      within "#champ-#{second_tdc.stable_id}" do
        find("label", text: 'Paris').click
      end
      expect(page).to have_selector(:button, text: "Déposer les modifications", disabled: true)
      within("#modal-eligibilite-rules-dialog") { click_on "Fermer" }

      # none of conditions matches, i can submit
      within "#champ-#{second_tdc.stable_id}" do
        find("label", text: 'Marseille').click
      end

      # it works, yay
      click_on "Déposer les modifications"
      wait_until { dossier.reload.en_construction? == true }
    end
  end
end
