require 'spec_helper'

feature 'On the description page' do
  let!(:dossier) { create(:dossier, :with_entreprise) }
  before do
    visit dossier_description_path dossier
  end
  scenario 'date_previsionnelle field is present' do
    expect(page).to have_css('#date_previsionnelle')
  end
  context 'when user clic on date_previsionnelle field', js: true do
    before do
      find_by_id('date_previsionnelle').click
    end
    scenario 'the datepicker popup is displayed' do
      expect(page).to have_css('.datepicker-days')
    end
  end
end