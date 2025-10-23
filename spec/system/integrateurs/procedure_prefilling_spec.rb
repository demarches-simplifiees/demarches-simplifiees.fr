# frozen_string_literal: true

describe 'As an integrator:', js: true do
  let(:procedure) { create(:procedure, :for_individual, :published, opendata: true) }
  let!(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }

  before { visit "/preremplir/#{procedure.path}" }

  scenario 'I can read the procedure prefilling (aka public champs)' do
    expect(page).to have_content(I18n.t("views.prefill_descriptions.edit.title.nom"))
    expect(page).to have_content(type_de_champ.to_typed_id_for_query)
    expect(page).to have_content(I18n.t("activerecord.attributes.type_de_champ.type_champs.#{type_de_champ.type_champ}"))
    expect(page).to have_content(type_de_champ.libelle)
    expect(page).to have_content(type_de_champ.description)
  end

  scenario 'I can select champs to prefill and get prefill link and prefill query' do
    page.find_by_id("#{type_de_champ.id}_add_button", match: :first).click

    # API en GET
    expect(page).to have_content("/commencer/#{procedure.path}?champ_#{type_de_champ.to_typed_id_for_query}=")

    # API en POST
    expect(page).to have_content("api/public/v1/demarches/#{procedure.id}/dossiers")
    expect(page).to have_content("{\"champ_#{type_de_champ.to_typed_id_for_query}\":")
  end
end
