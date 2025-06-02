# frozen_string_literal: true

require 'spec_helper'

describe 'users/activate/new.html.haml', type: :view do
  shared_examples "a password complexity scorer" do |complexity|
    context "complexity must be at leat #{complexity}" do
      before do
        assign(:user, user)
        render
      end

      it 'renders password form with complexity bar' do
        expect(rendered).to have_selector('#user_email[disabled]')
        expect(rendered).to have_selector("input[id=user_password][data-turbo-input-url-value='#{show_password_complexity_path(complexity)}']")
        expect(rendered).to have_selector('.fr-alert')
        expect(rendered).to have_selector('#password_complexity')
        expect(rendered).to have_selector('input[type=submit]')
      end
    end
  end

  context 'for user' do
    let(:user) { create :user }
    it_behaves_like "a password complexity scorer", 2
  end

  context 'for user' do
    let(:instructeur) { create :instructeur }
    let(:user) { instructeur.user }
    it_behaves_like "a password complexity scorer", 3
  end
end
