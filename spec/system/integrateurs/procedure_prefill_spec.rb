describe 'As an integrator:', js: true do
  let(:procedure) { create(:procedure, :published, opendata: true) }
  let!(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }

  before { visit "/description/#{procedure.path}" }

  scenario 'I can read the procedure description (aka public champs)' do
    expect(page).to have_content(type_de_champ.to_typed_id)
    expect(page).to have_content(I18n.t("activerecord.attributes.type_de_champ.type_champs.#{type_de_champ.type_champ}"))
    expect(page).to have_content(type_de_champ.libelle)
    expect(page).to have_content(type_de_champ.description)
  end

  scenario 'I can select champs to prefill' do
    click_on 'Ajouter'

    description = Description.new(procedure)
    description.update(selected_type_de_champ_ids: [type_de_champ.id.to_s])
    expect(page).to have_content(description.prefill_link)
  end
end
