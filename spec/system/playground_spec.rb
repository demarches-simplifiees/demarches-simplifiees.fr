# frozen_string_literal: true

describe 'the playground', js: true do
  let(:administrateur) { administrateurs(:default_admin) }
  let!(:procedure) { create(:procedure, administrateurs: [administrateur]) }
  before { sign_in administrateur.user }

  scenario 'I can display a page with all form fields and UI elements' do
    visit '/graphql'
    expect(page).to have_text('getDemarche')
    begin
      expect(page).to have_css('.graphiql-toolbar')
      page.find(".graphiql-toolbar button:first").click
      within(".graphiql-dropdown-content") do
        all(".graphiql-dropdown-item", text: "getDemarche").first.click
      end
      expect(page).to have_text("data")
      expect(page).to have_text("number")
      expect(page).to have_text(procedure.id)
    rescue Playwright::Error => e
      retry if e.message == "Element is not attached to the DOM" # avoid flacky
    end
  end
end
