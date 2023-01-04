shared_examples "the user has got a prefilled dossier, owned by themselves" do
  scenario "the user has got a prefilled dossier, owned by themselves" do
    siret = '41816609600051'
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}/)
      .to_return(status: 200, body: File.read('spec/fixtures/files/api_entreprise/etablissements.json'))

    expect(dossier.user).to eq(user)

    expect(page).to have_current_path siret_dossier_path(procedure.dossiers.last)
    fill_in 'Numéro SIRET', with: siret
    click_on 'Valider'

    expect(page).to have_current_path(etablissement_dossier_path(dossier))
    expect(page).to have_content('OCTO TECHNOLOGY')
    click_on 'Continuer avec ces informations'

    expect(page).to have_current_path(brouillon_dossier_path(dossier))
    expect(page).to have_field(type_de_champ_text.libelle, with: text_value)
    expect(page).to have_field(type_de_champ_phone.libelle, with: phone_value)
    expect(page).to have_css('label', text: type_de_champ_phone.libelle)
  end
end
