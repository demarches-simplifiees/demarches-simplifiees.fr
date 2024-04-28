# frozen_string_literal: true

shared_examples "the user has got a prefilled dossier, owned by themselves" do
  scenario "the user has got a prefilled dossier, owned by themselves" do
    expect(dossier.user).to eq(user)

    expect(page).to have_current_path identite_dossier_path(procedure.dossiers.last)

    within('.individual-infos') do
      expect(page).to have_field('Prénom', with: prenom_value)
      expect(page).to have_field('Nom', with: nom_value)
    end
    within "#identite-form" do
      click_on 'Continuer'
    end

    expect(page).to have_current_path(brouillon_dossier_path(dossier))
    expect(page).to have_field(type_de_champ_text.libelle, with: text_value)
    expect(page).to have_field(type_de_champ_phone.libelle, with: phone_value)
    expect(page).to have_css('label', text: type_de_champ_phone.libelle)
    expect(page).to have_field(type_de_champ_rna.libelle, with: rna_value)
    expect(page).to have_field(type_de_champ_siret.libelle, with: siret_value)
    expect(page).to have_css('legend', text: type_de_champ_repetition.libelle)
    expect(page).to have_field(text_repetition_libelle, with: text_repetition_value)
    expect(page).to have_field(integer_repetition_libelle, with: integer_repetition_value)
    expect(page).to have_field(type_de_champ_datetime.libelle, with: datetime_value)
    expect(page).to have_css('legend', text: type_de_champ_multiple_drop_down_list.libelle)
    expect(page).to have_content(multiple_drop_down_list_values.first)
    expect(page).to have_content(multiple_drop_down_list_values.last)
    expect(page).to have_field("Le département de l’EPCI", with: epci_value.first)
    expect(page).to have_selector("option[value='#{epci_value.last}'][selected]")
    expect(page).to have_field(type_de_champ_dossier_link.libelle, with: dossier_link_value)
    expect(page).to have_field(type_de_champ_commune.libelle, with: commune_libelle)
    expect(page).to have_content(annuaire_education_value.last)
    expect(page).to have_content(address_value.last)
  end
end
