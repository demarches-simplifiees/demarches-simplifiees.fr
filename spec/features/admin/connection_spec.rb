require 'spec_helper'

feature 'Administrator connection' do
  include ActiveJob::TestHelper

  let(:email) { 'admin1@admin.com' }
  let(:password) { 'mon chien aime les bananes' }
  let!(:admin) { create(:administrateur, email: email, password: password) }
  let!(:gestionnaire) { create(:gestionnaire, :with_trusted_device, email: email, password: password) }

  before do
    visit new_administrateur_session_path
  end

  scenario 'administrator is on sign in page' do
    expect(page).to have_css('#new_user')
  end

  context "admin fills form and log in" do
    before do
      sign_in_with(email, password, true)
    end

    scenario 'a menu button is available' do
      expect(page).to have_css('#admin_menu')
    end

    context 'when he click on the menu' do
      before do
        page.find_by_id('admin_menu').click
      end
      scenario 'it displays the menu' do
        expect(page).to have_css('a#profile')
        expect(page).to have_css('#sign-out')
      end
      context 'when clicking on sign-out' do
        before do
          stub_request(:get, "https://api.github.com/repos/betagouv/tps/releases/latest")
            .to_return(:status => 200, :body => '{"tag_name": "plip", "body": "blabla", "published_at": "2016-02-09T16:46:47Z"}', :headers => {})

          page.find_by_id('sign-out').find('a').click
        end
        scenario 'admin is redireted to home page' do
          expect(page).to have_css('.landing')
        end
      end
      context 'when clicking on profile' do
        before do
          page.find_by_id('profile').click
        end
        scenario 'it redirects to profile page' do
          expect(page).to have_css('#profil-page')
        end
        context 'when clicking on procedure' do
          before do
            page.click_on('Tableau de bord').click
          end

          scenario 'it redirects to procedure page' do
            expect(page).to have_content('Démarches')
          end
        end
      end
    end
  end
end
