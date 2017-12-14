require 'spec_helper'

feature 'on click on tabs button' do
  let(:user) { create :user }

  let(:dossier_invite) { create(:dossier, :with_entreprise, user: create(:user), state: 'en_construction') }

  before do
    create(:dossier, :with_entreprise, user: user, state: 'en_construction')
    create(:dossier, :with_entreprise, user: user, state: 'en_instruction')
    create(:dossier, :with_entreprise, user: user, state: 'closed')
    create(:dossier, :with_entreprise, user: user, state: 'refused')
    create(:dossier, :with_entreprise, user: user, state: 'without_continuation')

    create :invite, dossier: dossier_invite, user: user

    login_as user, scope: :user
  end

  context 'when user is logged in' do
    context 'when he click on tabs en construction' do
      before do
        visit users_dossiers_url(liste: :a_traiter)
        page.click_on 'En construction 1'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users-index')
      end
    end

    context 'when he click on tabs en examen' do
      before do
        visit users_dossiers_url(liste: :en_instruction)
        page.click_on 'En instruction 1'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users-index')
      end
    end

    context 'when he click on tabs termine' do
      before do
        visit users_dossiers_url(liste: :termine)
        page.click_on 'Terminé 3'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users-index')
      end
    end

    context 'when he click on tabs invitation' do
      before do
        visit users_dossiers_url(liste: :invite)
        page.click_on 'Invitation 1'
      end

      scenario 'it redirect to users dossier invites' do
        expect(page).to have_css('#users-index')
      end
    end
  end
end
