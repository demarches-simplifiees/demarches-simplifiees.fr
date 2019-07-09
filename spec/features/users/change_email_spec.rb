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

    user.reload
    expect(user.email).to eq(old_email)
    expect(user.unconfirmed_email).to eq(new_email)

    click_confirmation_link_for(new_email)

    user.reload
    expect(user.email).to eq(new_email)
    expect(user.unconfirmed_email).to be_nil
  end
end
