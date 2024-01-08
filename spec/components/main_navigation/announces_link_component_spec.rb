# frozen_string_literal: true

require "rails_helper"

RSpec.describe MainNavigation::AnnouncesLinkComponent, type: :component do
  let(:user) { build(:user) }
  let!(:admin_release_note) { create(:release_note, released_on: Date.yesterday, categories: ["administrateur"]) }
  let!(:instructeur_release_note) { create(:release_note, released_on: Date.yesterday, categories: ["instructeur"]) }
  let(:not_published_release_note) { create(:release_note, published: false, released_on: Date.tomorrow) }

  let(:as_administrateur) { false }
  let(:as_instructeur) { false }

  before do
    if as_administrateur
      user.build_administrateur
    end

    if as_instructeur
      user.build_instructeur
    end

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  subject { render_inline(described_class.new) }

  context 'when signed as simple user' do
    it 'does not render the announcements link if not signed in' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when no signed in' do
    let(:current_user) { nil }

    it 'does not render the announcements link if not signed in' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when instructeur signed in' do
    let(:as_instructeur) { true }

    it 'renders the announcements link' do
      expect(subject).to have_link("Nouveautés")
    end

    context 'when there are new announcements' do
      before do
        user.announces_seen_at = 5.days.ago
      end

      it 'does not render the notification badge' do
        expect(subject).to have_link("Nouveautés")
        expect(subject).to have_css(".notifications")
      end
    end

    context 'when there are no new announcements' do
      before do
        user.announces_seen_at = 1.minute.ago
      end

      it 'does not render the notification badge' do
        expect(subject).to have_link("Nouveautés")
        expect(subject).not_to have_css(".notifications")
      end
    end

    context 'when there are no announcement at all' do
      let(:instructeur_release_note) { nil }

      it 'does not render anything' do
        expect(subject.to_html).to be_empty
      end
    end
  end

  context 'when administrateur signed in' do
    let(:as_administrateur) { true }

    it 'renders the announcements link' do
      expect(subject).to have_link("Nouveautés")
    end
  end
end
