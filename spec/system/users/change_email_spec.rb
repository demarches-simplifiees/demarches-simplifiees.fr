# frozen_string_literal: true

describe 'Changing an email' do
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

describe 'Merging account' do
  let(:old_user) { create(:user) }
  let(:new_user) { create(:user) }

  before do
    login_as old_user, scope: :user
  end

  scenario 'is easy' do
    visit '/profil'

    fill_in :user_email, with: new_user.email

    perform_enqueued_jobs do
      click_button 'Changer mon adresse'
    end

    expect(page).to have_content(I18n.t('devise.registrations.update_needs_confirmation'))
    expect(page).to have_content(old_user.email)
    expect(page).to have_content(new_user.email)

    login_as new_user, scope: :user
    visit '/profil'

    expect(page).to have_content("Acceptez-vous d’absorber le compte de #{old_user.email}")
    click_on 'Accepter la fusion'

    expect(page).not_to have_content(old_user.email)
    expect(page).to have_content(new_user.email)
    expect { old_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
