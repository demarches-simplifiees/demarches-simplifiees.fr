# frozen_string_literal: true

RSpec.describe Instructeurs::EnConstructionMenuComponent, type: :component do
  include DossierHelper

  subject do
    component = described_class.new(dossier:)
    allow(component).to receive(:statut).and_return('a-suivre')
    render_inline(component)
  end

  matcher :have_dropdown_title do |expected_title|
    match do |subject|
      expect(subject).to have_selector('.dropdown .dropdown-button', text: expected_title)
    end
  end

  matcher :have_dropdown_items do |options|
    match do |subject|
      expected_count = options[:count] || 1
      expect(subject).to have_selector('ul.dropdown-items li:not(.hidden)', count: expected_count)
    end
  end

  matcher :have_dropdown_item do |expected_title, options = {}|
    match do |subject|
      expected_href = options[:href]
      if (expected_href.present?)
        expect(subject).to have_selector("ul.dropdown-items li a[href='#{expected_href}']", text: expected_title)
      else
        expect(subject).to have_selector('ul.dropdown-items li', text: expected_title)
      end
    end
  end

  context 'en_construction' do
    let(:dossier) { create(:dossier, :en_construction) }

    it 'renders a dropdown' do
      expect(subject).to have_dropdown_title('Demander une correction')
      expect(subject).to have_dropdown_items(count: 2) # form is already expanded so we have 2 visible items
    end
  end

  context 'en_instruction' do
    let(:dossier) { create(:dossier, :en_instruction) }

    it 'renders a dropdown' do
      expect(subject).to have_dropdown_title('Repasser en construction')
      expect(subject).to have_dropdown_item('Demander une correction')
      expect(subject).to have_dropdown_item('Repasser en construction')
      expect(subject).to have_dropdown_items(count: 3)
    end

    context 'when procedure is sva' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: create(:procedure, :sva)) }

      it 'renders a dropdown' do
        expect(subject).to have_dropdown_title('Demander une correction')
        expect(subject).to have_dropdown_item('Demander une correction')
        expect(subject).to have_dropdown_item('Demander à compléter')
        expect(subject).to have_dropdown_items(count: 4)
        expect(subject).to have_text('Le délai du SVA')
      end
    end

    context 'when procedure is svr' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: create(:procedure, :svr)) }

      it 'renders a dropdown' do
        expect(subject).to have_dropdown_title('Demander une correction')
        expect(subject).to have_dropdown_item('Demander une correction')
        expect(subject).to have_dropdown_item('Demander à compléter')
        expect(subject).to have_dropdown_items(count: 4)
        expect(subject).to have_text('Le délai du SVR')
      end
    end
  end
end
