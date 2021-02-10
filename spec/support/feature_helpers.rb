module FeatureHelpers
  include ActiveJob::TestHelper

  def login_admin
    user = create :user
    login_as user, scope: :user
    user
  end

  def login_instructeur
    instructeur = create(:instructeur)
    login_as instructeur, scope: :instructeur
  end

  def sign_in_with(email, password, sign_in_by_link = false)
    fill_in :user_email, with: email
    fill_in :user_password, with: password

    if sign_in_by_link
      Flipper.disable(:instructeur_bypass_email_login_token)
    end

    perform_enqueued_jobs do
      click_on 'Se connecter'
    end

    if sign_in_by_link
      mail = ActionMailer::Base.deliveries.last
      message = mail.html_part.body.raw_source
      instructeur_id = message[/\".+\/connexion-par-jeton\/(.+)\?jeton=(.*)\"/, 1]
      jeton = message[/\".+\/connexion-par-jeton\/(.+)\?jeton=(.*)\"/, 2]

      visit sign_in_by_link_path(instructeur_id, jeton: jeton)
    end
  end

  def sign_up_with(email, password = 'my-s3cure-p4ssword')
    fill_in :user_email, with: email
    fill_in :user_password, with: password

    perform_enqueued_jobs do
      click_button 'Créer un compte'
    end
  end

  def click_confirmation_link_for(email, in_another_browser: false)
    confirmation_email = open_email(email)
    confirmation_link = confirmation_email.body.match(/href="[^"]*(\/users\/confirmation[^"]*)"/)[1]

    if in_another_browser
      # Simulate the user opening the link in another browser, thus loosing the session cookie
      Capybara.reset_session!
    end

    visit confirmation_link
  end

  def click_procedure_sign_in_link_for(email)
    confirmation_email = open_email(email)
    procedure_sign_in_link = confirmation_email.body.match(/href="([^"]*\/commencer\/[^"]*)"/)[1]

    visit procedure_sign_in_link
  end

  def click_reset_password_link_for(email)
    reset_password_email = open_email(email)
    token_params = reset_password_email.body.match(/reset_password_token=[^"]+/)

    visit "/users/password/edit?#{token_params}"
  end

  # Add a new type de champ in the procedure editor
  def add_champ(options = {})
    add_champs(**options)
  end

  # Add several new type de champ in the procedure editor
  def add_champs(count: 1, remove_flash_message: false)
    within '.buttons' do
      count.times { click_on 'Ajouter un champ' }
    end

    if remove_flash_message
      expect(page).to have_button('Ajouter un champ', disabled: false)
      expect(page).to have_content('Formulaire enregistré')
      execute_script("document.querySelector('#flash_message').remove();")
    end
  end

  def blur
    page.find('body').click
  end

  def pause
    $stderr.write 'Spec paused. Press enter to continue:'
    $stdin.gets
  end

  def wait_until
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep(0.1) until (value = yield)
      value
    end
  end

  # Keep the brower window open after a test success of failure, to
  # allow inspecting the page or the console.
  #
  # Usage:
  #  1. Disable the 'headless' mode in `spec_helper.rb`
  #  2. Call `leave_browser_open` at the beginning of your scenario
  def leave_browser_open
    Selenium::WebDriver::Chrome::Service.class_eval do
      def stop
        STDOUT.puts "#{self.class}#stop is a no-op, because leave_browser_open is enabled"
      end
    end

    Selenium::WebDriver::Driver.class_eval do
      def quit
        STDOUT.puts "#{self.class}#quit is a no-op, because leave_browser_open is enabled"
      end
    end

    Capybara::Selenium::Driver.class_eval do
      def reset!
        STDOUT.puts "#{self.class}#reset! is a no-op, because leave_browser_open is enabled"
      end
    end
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
