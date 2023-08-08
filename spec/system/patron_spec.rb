describe 'Accessing the /patron page:' do
  scenario 'I can display a page with all form fields and UI elements' do
    visit patron_path
    expect(page).to have_text('Icônes')
    expect(page).to have_text('Formulaires')
    expect(page).to have_text('Boutons')
  end
end
