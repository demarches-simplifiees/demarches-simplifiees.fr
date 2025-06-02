# frozen_string_literal: true

describe 'Protecting against request forgeries:', :allow_forgery_protection, :show_exception_pages do
  let(:user) { create(:user, password: password) }
  let(:password) { SECURE_PASSWORD }

  before do
    visit new_user_session_path
  end

  context 'when the browser send a request after the session cookie expired' do
    before do
      delete_session_cookie
    end

    context 'when the long-lived CSRF cookie is still present' do
      scenario 'the change is allowed' do
        fill_sign_in_form
        click_on 'Se connecter'
        expect(page).to have_content('Connecté')
      end
    end

    context 'when the long-lived CSRF cookie is invalid or missing' do
      before do
        delete_long_lived_csrf_cookie
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

  def delete_session_cookie
    session_cookie_name = Rails.application.config.session_options[:key]
    delete_cookie(session_cookie_name)
  end

  def delete_long_lived_csrf_cookie
    csrf_cookie_name = ApplicationController::LongLivedAuthenticityToken::COOKIE_NAME
    delete_cookie(csrf_cookie_name)
  end

  def delete_cookie(cookie_name)
    raise 'The cookie to be deleted can’t be nil' if cookie_name.nil?
    page.driver.browser.set_cookie("#{cookie_name}=''")
  end
end
