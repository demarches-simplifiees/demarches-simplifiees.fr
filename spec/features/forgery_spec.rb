feature 'Protecting against request forgeries:', :allow_forgery_protection, :show_exception_pages do
  let(:user) { create(:user, password: password) }
  let(:password) { 'ThisIsTheUserPassword' }

  scenario 'a form without a matching CSRF token is rejected' do
    visit new_user_session_path

    delete_session_cookie
    fill_sign_in_form

    click_on 'Se connecter'
    expect(page).to have_text('L’action demandée a été rejetée')
  end

  private

  def fill_sign_in_form
    fill_in :user_email, with: user.email
    fill_in :user_password, with: password
  end

  def delete_session_cookie
    session_cookie_name = Rails.application.config.session_options[:key]
    page.driver.browser.set_cookie("#{session_cookie_name}=''")
  end
end
