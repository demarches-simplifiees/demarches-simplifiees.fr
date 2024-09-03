# frozen_string_literal: true

describe MainNavigation::InstructeurExpertNavigationComponent, type: :component do
  let(:component) { described_class.new }
  let(:as_instructeur) { true }
  let(:as_expert) { false }
  let(:controller_name) { 'dossiers' }
  let(:user) { build(:user) }

  subject { render_inline(component) }

  before do
    if as_instructeur
      user.build_instructeur
    end

    if as_expert
      user.build_expert
    end

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:administrateur_signed_in?).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:controller_name).and_return(controller_name)
  end

  describe 'when instructor is signed in' do
    it 'renders a link to instructeur procedures with current page class' do
      expect(subject).to have_link('Démarches', href: component.helpers.instructeur_procedures_path)
      expect(subject).to have_selector('a[aria-current="true"]', text: 'Démarches')
    end

    it 'does not have Avis' do
      expect(subject).not_to have_link('Avis')
    end

    context 'when instructor is also an expert' do
      let(:as_expert) { true }
      before do
        allow(user.expert).to receive(:avis_summary).and_return({ unanswered: 0 })
      end

      it 'render have Avis link' do
        expect(subject).to have_link('Avis', href: component.helpers.expert_all_avis_path)
        expect(subject).not_to have_selector('a[aria-current="true"]', text: 'Avis')
      end
    end

    context 'when there are release notes' do
      let!(:release_note) { create(:release_note, categories: ['instructeur']) }

      it 'renders a link to Announces page' do
        expect(subject).to have_link('Nouveautés')
      end
    end
  end

  describe 'when expert is signed in' do
    let(:as_instructeur) { false }
    let(:as_expert) { true }

    let(:unanswered) { 0 }
    let(:controller_name) { 'avis' }

    before do
      allow(user.expert).to receive(:avis_summary).and_return({ unanswered: })
    end

    it 'renders a link to expert all avis with current page class' do
      expect(subject).to have_link('Avis', href: component.helpers.expert_all_avis_path)
      expect(subject).to have_selector('a[aria-current="true"]', text: 'Avis')
      expect(subject).not_to have_selector('span.badge')
    end

    it 'does not have Démarches link' do
      expect(subject).not_to have_link('Démarches')
    end

    context 'when there are unanswered avis' do
      let(:unanswered) { 2 }

      it 'renders an unanswered avis badge for the expert' do
        expect(subject).to have_selector('span.badge.warning', text: '2')
      end
    end

    context 'when expert is also instructor' do
      let(:as_instructeur) { true }

      it 'render have Démarches link' do
        expect(subject).to have_link('Démarches', href: component.helpers.instructeur_procedures_path)
        expect(subject).not_to have_selector('a[aria-current="true"]', text: 'Démarches')
      end
    end
  end
end
