# frozen_string_literal: true

describe AccountDropdownComponent, type: :component do
  let(:component) { described_class.new(dossier:, nav_bar_profile:) }
  let(:dossier) { nil }
  let(:nav_bar_profile) { :user }
  let(:user) { build(:user) }

  subject { render_inline(component) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:super_admin_signed_in?).and_return(false)
  end

  describe 'basic display' do
    it 'shows user email' do
      expect(subject).to have_text(user.email)
    end

    context 'when guest profile' do
      let(:nav_bar_profile) { :guest }
      let(:user) { nil }

      it 'does not show profile badge' do
        expect(subject).not_to have_css('.fr-badge')
      end
    end
  end

  describe 'profile switching' do
    context 'when user profile' do
      let(:nav_bar_profile) { :user }

      before do
        allow_any_instance_of(ApplicationController).to receive(:instructeur_signed_in?).and_return(true)
      end

      it 'shows instructor switch option' do
        expect(subject).to have_link('Passer en instructeur')
        expect(subject).not_to have_link('Passer en usager')
      end
    end

    context 'when instructor profile' do
      let(:nav_bar_profile) { :instructeur }

      before do
        allow_any_instance_of(ApplicationController).to receive(:instructeur_signed_in?).and_return(true)
      end

      it 'shows user switch option' do
        expect(subject).to have_link('Passer en usager')
        expect(subject).not_to have_link('Passer en instructeur')
      end
    end
  end
end
