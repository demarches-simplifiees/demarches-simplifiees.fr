# frozen_string_literal: true

require 'spec_helper'

describe 'users/activate/new.html.haml', type: :view do
  shared_examples "a password complexity scorer" do |complexity|
    before do
      assign(:user, user)
      render
    end

    it "where password form show complexity bar with at least complexity of #{complexity}" do
      expect(rendered).to have_selector('#user_email[disabled]')
      expect(rendered).to have_selector("input[id=user_password][data-turbo-input-url-value='#{show_password_complexity_path(complexity)}']")
      expect(rendered).to have_selector('.fr-alert')
      expect(rendered).to have_selector('#password_complexity')
      expect(rendered).to have_selector('input[type=submit]')
    end
  end

  context 'user activation' do
    let(:user) { create :user }
    it_behaves_like "a password complexity scorer", 2
  end

  context 'instructeur activation' do
    let(:instructeur) { create :instructeur }
    let(:user) { instructeur.user }
    it_behaves_like "a password complexity scorer", 3
  end

  context 'administrateur activation' do
    let(:administrateur) { create :administrateur }
    let(:user) { administrateur.user }
    it_behaves_like "a password complexity scorer", 4
  end

  context 'gestionnaire activation' do
    let(:gestionnaire) { create :gestionnaire }
    let(:user) { gestionnaire.user }
    it_behaves_like "a password complexity scorer", 4
  end
end
