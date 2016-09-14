require 'spec_helper'

feature 'on click on tabs button' do
  let(:user) { create :user }

  let(:dossier_invite) { create(:dossier, :with_entreprise, user: create(:user), state: 'initiated') }

  before do
    create(:dossier, :with_entreprise, user: user, state: 'initiated')
    create(:dossier, :with_entreprise, user: user, state: 'replied')
    create(:dossier, :with_entreprise, user: user, state: 'updated')
    create(:dossier, :with_entreprise, user: user, state: 'validated')
    create(:dossier, :with_entreprise, user: user, state: 'submitted')
    create(:dossier, :with_entreprise, user: user, state: 'received')
    create(:dossier, :with_entreprise, user: user, state: 'closed')
    create(:dossier, :with_entreprise, user: user, state: 'refused')
    create(:dossier, :with_entreprise, user: user, state: 'without_continuation')

    create :invite, dossier: dossier_invite, user: user

    login_as user, scope: :user
  end

  context 'when user is logged in' do
    context 'when he click on tabs nouveaux' do
      before do
        visit users_dossiers_url(liste: :nouveaux)
        page.click_on 'Nouveaux 1'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users_index')
      end
    end

    context 'when he click on tabs a traite' do
      before do
        visit users_dossiers_url(liste: :a_traiter)
        page.click_on 'Action requise 1'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users_index')
      end
    end

    context 'when he click on tabs en attente' do
      before do
        visit users_dossiers_url(liste: :en_attente)
        page.click_on 'Etude en cours 1'
      end

      scenario 'it redirect to users dossier en attente' do
        expect(page).to have_css('#users_index')
      end
    end

    context 'when he click on tabs a deposes' do
      before do
        visit users_dossiers_url(liste: :valides)
        page.click_on 'À déposer 1'
      end

      scenario 'it redirect to users dossier deposes' do
        expect(page).to have_css('#users_index')
      end
    end

    context 'when he click on tabs en examen' do
      before do
        visit users_dossiers_url(liste: :en_instruction)
        page.click_on 'En examen 2'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users_index')
      end
    end

    context 'when he click on tabs termine' do
      before do
        visit users_dossiers_url(liste: :termine)
        page.click_on 'Cloturé 3'
      end

      scenario 'it redirect to users dossier termine' do
        expect(page).to have_css('#users_index')
      end
    end

    context 'when he click on tabs invitation' do
      before do
        visit users_dossiers_url(liste: :invite)
        page.click_on 'Invitation 1'
      end

      scenario 'it redirect to users dossier invites' do
        expect(page).to have_css('#users_index')
      end
    end
  end
end