# frozen_string_literal: true

describe 'Protecting against request forgeries:', :allow_forgery_protection, :show_exception_pages do
  let(:user) { users(:default_user) }
  let(:password) { SECURE_PASSWORD }
  let(:assert_text) { "Mes dossiers" }

  before do
    visit new_user_session_path
  end

  context 'when the browser send a request after the session cookie expired' do
    context 'when the CSRF cookie is still present' do
      scenario 'the change is allowed' do
        fill_sign_in_form
        click_on 'Se connecter'
        expect(page).to have_text(assert_text) # not in plain text because error page renders this line, which would lead to a false negative
      end
    end

    context 'when session cookie is invalid or missing' do
      before do
        delete_csrf_token
      end

      scenario 'the user sees an error page' do
        fill_sign_in_form
        click_on 'Se connecter'
        expect(page).to have_text('L’action demandée a été rejetée')
      end
    end
  end

  private

  def fill_sign_in_form
    fill_in :user_email, with: user.email
    fill_in :user_password, with: password
  end

  def delete_csrf_token
    page.driver.browser.set_cookie("csrf_token=''")
  end
end
