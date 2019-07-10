require 'spec_helper'

feature 'Changing an email' do
  let(:old_email) { 'old@email.com' }
  let(:user) { create(:user, email: old_email) }

  before do
    login_as user, scope: :user
  end

  scenario 'is easy' do
    new_email = 'new@email.com'

    visit '/profil'

    fill_in :user_email, with: new_email

    perform_enqueued_jobs do
      click_button 'Changer mon adresse'
    end

    expect(page).to have_content(I18n.t('devise.registrations.update_needs_confirmation'))
    expect(page).to have_content(old_email)
    expect(page).to have_content(new_email)

    click_confirmation_link_for(new_email)

    expect(page).to have_content(I18n.t('devise.confirmations.confirmed'))
    expect(page).not_to have_content(old_email)
    expect(page).to have_content(new_email)
    expect(user.reload.email).to eq(new_email)
  end
end
