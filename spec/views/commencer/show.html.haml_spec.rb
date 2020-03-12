require 'rails_helper'

RSpec.describe 'commencer/show.html.haml', type: :view do
  include Rails.application.routes.url_helpers

  let(:procedure) { create(:procedure, :published, :for_individual, :with_service) }

  before do
    assign(:procedure, procedure)
    if user
      sign_in user
    end
  end

  subject { render }

  context 'when no user is signed in' do
    let(:user) { nil }

    it 'renders sign-in and sign-up links' do
      subject
      expect(rendered).to have_field('Email')
      expect(rendered).to have_field('Mot de passe')
      expect(rendered).to have_button('Se connecter')
      expect(rendered).to have_link("S'inscrire")
      if ENV['GOOGLE_CLIENT_ID'].present?
        expect(rendered).to have_link('Gmail, Google')
      end
      if ENV['MICROSOFT_CLIENT_ID'].present?
        expect(rendered).to have_link('Hotmail, Microsoft')
      end
      if ENV['YAHOO_CLIENT_ID'].present?
        expect(rendered).to have_link('Yahoo!')
      end
      if ENV['FC_PARTICULIER_ID'].present?
        expect(rendered).to have_link('S’identifier avec FranceConnect')
      end
    end
  end

  context 'when the user is already signed in' do
    let(:user) { create :user }

    shared_examples_for 'it renders a link to create a new dossier' do |button_label|
      it 'renders a link to create a new dossier' do
        subject
        expect(rendered).to have_link(button_label, href: new_dossier_url(procedure_id: procedure.id))
      end
    end

    context 'and they don’t have any dossier on this procedure' do
      it_behaves_like 'it renders a link to create a new dossier', 'Commencer la démarche'
    end

    context 'and they have a pending draft' do
      let!(:brouillon) { create(:dossier, user: user, procedure: procedure) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to resume the pending draft' do
        subject
        expect(rendered).to have_text(time_ago_in_words(brouillon.created_at))
        expect(rendered).to have_link('Continuer à remplir mon dossier', href: brouillon_dossier_path(brouillon))
      end
    end

    context 'and they have a submitted dossier' do
      let!(:brouillon) { create(:dossier, user: user, procedure: procedure) }
      let!(:dossier) { create(:dossier, :en_construction, :with_individual, user: user, procedure: procedure) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to the submitted dossier' do
        subject
        expect(rendered).to have_text(time_ago_in_words(dossier.en_construction_at))
        expect(rendered).to have_link('Voir mon dossier', href: dossier_path(dossier))
      end
    end

    context 'and they have several submitted dossiers' do
      let!(:brouillon) { create(:dossier, user: user, procedure: procedure) }
      let!(:dossiers) { create_list(:dossier, 2, :en_construction, :with_individual, user: user, procedure: procedure) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to the dossiers list' do
        subject
        expect(rendered).to have_link('Voir mes dossiers en cours', href: dossiers_path)
      end
    end
  end
end
