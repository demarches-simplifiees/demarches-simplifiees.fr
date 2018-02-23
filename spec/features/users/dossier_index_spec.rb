require 'spec_helper'

feature 'As a User I want to sort and paginate dossiers', js: true do
  let(:user) { create(:user) }
  let(:procedure_for_individual) { create(:procedure, :published, :for_individual, ask_birthday: true) }

  before "Create dossier" do
    login_as user, scope: :user

    50.times do
      Dossier.create(procedure_id: procedure_for_individual.id, user_id: user.id, state: "en_construction")
    end

    visit root_path
  end

  context 'After sign_in, I can see my 51 dossiers on the index' do
    scenario 'Using sort' do
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq(user.dossiers.first.id.to_s)
      expect(page.all(:css, '#dossiers-list tr')[2].text.split(" ").first).to eq(user.dossiers.second.id.to_s)
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=desc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id + 49).to_s)
      expect(page.all(:css, '#dossiers-list tr')[2].text.split(" ").first).to eq((user.dossiers.first.id + 48).to_s)
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq(user.dossiers.first.id.to_s)
      expect(page.all(:css, '#dossiers-list tr')[2].text.split(" ").first).to eq(user.dossiers.second.id.to_s)
    end

    scenario 'Using pagination' do
      visit "/users/dossiers?dossiers_smart_listing[sort][id]=asc"
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq(user.dossiers.first.id.to_s)
      page.find('.next_page a').click
      wait_for_ajax
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id + 10).to_s)
      page.find('.next_page a').click
      wait_for_ajax
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id + 20).to_s)
      page.find('.prev a').click
      wait_for_ajax
      page.find('.prev a').click
      wait_for_ajax
      expect(page.all(:css, '#dossiers-list tr')[1].text.split(" ").first).to eq((user.dossiers.first.id).to_s)
    end
  end
end
