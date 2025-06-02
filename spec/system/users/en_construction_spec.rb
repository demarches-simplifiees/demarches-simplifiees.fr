# frozen_string_literal: true

describe "Dossier en_construction", js: true do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :for_individual, types_de_champ_public:) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_populated_champs, user:, procedure:) }
  let(:mandatory) { false }
  let(:types_de_champ_public) { [{ type: :piece_justificative, stable_id: 99, mandatory: }] }
  let(:champ) { dossier.project_champs_public.find { _1.stable_id == 99 } }

  def user_buffer_champ
    dossier.reload.with_update_stream(user).project_champs_public.find { _1.stable_id == 99 }
  end

  scenario 'delete a non mandatory piece justificative' do
    visit_dossier(dossier)

    expect(page).not_to have_button("Remplacer")
    click_on "Supprimer le fichier toto.txt"

    wait_until { user_buffer_champ.blank? }
    expect(page).to have_text("La pièce jointe (toto.txt) a bien été supprimée. Vous pouvez en ajouter une autre.")
  end

  context "with a mandatory piece justificative" do
    let(:mandatory) { true }

    scenario 'remplace a mandatory piece justificative' do
      visit_dossier(dossier)

      click_on "Supprimer le fichier toto.txt"
      expect(page).to have_text("La pièce jointe (toto.txt) a bien été supprimée. Vous pouvez en ajouter une autre.")

      input_selector = "#attachment-multiple-empty-#{champ.public_id}"
      expect(page).to have_selector(input_selector)
      find(input_selector).attach_file(Rails.root.join('spec/fixtures/files/file.pdf'))

      wait_until { user_buffer_champ.piece_justificative_file.first&.filename == 'file.pdf' }
      expect(page).to have_text("file.pdf")
    end
  end

  context "with a mandatory titre identite" do
    let(:types_de_champ_public) { [{ type: :titre_identite, stable_id: 99, mandatory: true }] }

    scenario 'remplace a mandatory titre identite' do
      visit_dossier(dossier)

      click_on "Supprimer le fichier toto.png"
      expect(page).to have_text("La pièce jointe (toto.png) a bien été supprimée. Vous pouvez en ajouter une autre.")

      input_selector = "##{champ.focusable_input_id}"
      expect(page).to have_selector(input_selector)
      find(input_selector).attach_file(Rails.root.join('spec/fixtures/files/file.pdf'))

      expect(page).to have_text("file.pdf")
    end
  end

  private

  def visit_dossier(dossier)
    visit modifier_dossier_path(dossier)

    expect(page).to have_current_path(new_user_session_path)
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_on 'Se connecter'

    expect(page).to have_current_path(modifier_dossier_path(dossier))
  end
end
