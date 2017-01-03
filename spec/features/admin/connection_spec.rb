require 'spec_helper'

feature 'Administrator connection' do
  let(:admin) { create(:administrateur) }
  before do
    visit new_administrateur_session_path
  end
  scenario 'administrator is on admin loggin page' do
    expect(page).to have_css('#form_login.user_connexion_page')
  end

  context "admin fills form and log in" do
    before do
      page.find_by_id('user_email').set admin.email
      page.find_by_id('user_password').set admin.password
      page.click_on 'Se connecter'
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
        expect(page).to have_css('#sign_out')
        expect(page).to have_css('a.fa-sign-out')
      end
      context 'when clicking on sign_out' do
        before do
          stub_request(:get, "https://api.github.com/repos/sgmap/tps/releases/latest").
              to_return(:status => 200, :body => '{"tag_name": "plip", "body": "blabla", "published_at": "2016-02-09T16:46:47Z"}', :headers => {})

          page.find_by_id('sign_out').find('a.fa-sign-out').click
        end
        scenario 'admin is redireted to home page' do
          expect(page).to have_css('#landing')
        end
      end
      context 'when clicking on profile' do
        before do
          page.find_by_id('profile').click
        end
        scenario 'it redirects to profile page' do
          expect(page).to have_css('#profile_page')
        end
        context 'when clicking on procedure' do
          before do
            page.find_by_id('admin_menu').click
            page.find_by_id('menu_item_procedure').click
          end

          scenario 'it redirects to procedure page' do
            expect(page).to have_content('Procédures')
          end
        end
      end
    end

  end
end
