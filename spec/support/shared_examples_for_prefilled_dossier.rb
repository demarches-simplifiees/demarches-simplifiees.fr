shared_examples "the user has got a prefilled dossier, owned by themselves" do
  scenario "the user has got a prefilled dossier, owned by themselves" do
    siret = '41816609600051'
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))

    expect(dossier.user).to eq(user)

    expect(page).to have_current_path siret_dossier_path(procedure.dossiers.last)
    fill_in 'Numéro TAHITI', with: siret
    click_on 'Valider'

    expect(page).to have_current_path(etablissement_dossier_path(dossier))
    expect(page).to have_content('OCTO TECHNOLOGY')
    click_on 'Continuer avec ces informations'

    expect(page).to have_current_path(brouillon_dossier_path(dossier))
    expect(page).to have_field(type_de_champ_text.libelle, with: text_value)
    expect(page).to have_field(type_de_champ_phone.libelle, with: phone_value)
    expect(page).to have_css('label', text: type_de_champ_phone.libelle)
    expect(page).to have_css('h3', text: type_de_champ_repetition.libelle)
    expect(page).to have_field(text_repetition_libelle, with: text_repetition_value)
    expect(page).to have_field(integer_repetition_libelle, with: integer_repetition_value)
    expect(page).to have_field(type_de_champ_datetime.libelle, with: datetime_value)
    expect(page).to have_css('label', text: type_de_champ_multiple_drop_down_list.libelle)
    expect(page).to have_content(multiple_drop_down_list_values.first)
    expect(page).to have_content(multiple_drop_down_list_values.last)
    expect(page).to have_field(type_de_champ_epci.libelle, with: epci_value.last)
  end
end
