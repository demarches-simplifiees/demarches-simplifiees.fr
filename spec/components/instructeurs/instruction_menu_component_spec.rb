# frozen_string_literal: true

RSpec.describe Instructeurs::InstructionMenuComponent, type: :component do
  include DossierHelper

  subject do
    render_inline(described_class.new(dossier:))
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

    it 'does not render' do
      expect(subject.to_s).to be_empty
    end
  end

  context 'en_instruction' do
    let(:dossier) { create(:dossier, :en_instruction) }
    it 'renders a dropdown' do
      expect(subject).to have_dropdown_title('Instruire le dossier')
      expect(subject).to have_dropdown_items(count: 3)
      expect(subject).to have_dropdown_item('Accepter')
      expect(subject).to have_dropdown_item('Classer sans suite')
      expect(subject).to have_dropdown_item('Refuser')
      expect(subject).to have_selector('#alert-error-annotation', text: "Les annotations privées n'ont pas été renseignées correctement et sont nécessaire pour apporter une décision sur le dossier.", visible: false)
    end
  end

  context 'en_instruction with annotations privees mandatory' do
    let(:procedure) { create(:procedure, types_de_champ_private:) }
    let(:dossier) { create(:dossier, :en_instruction, procedure:) }
    let(:types_de_champ_public) { [] }
    let(:types_de_champ_private)  { [{ type: :text, mandatory: true }] }

    it 'renders an alert if annotations privees are not valid' do
      expect(subject).to have_selector('#alert-error-annotation', text: "Les annotations privées n'ont pas été renseignées correctement et sont nécessaire pour apporter une décision sur le dossier.", visible: true)
    end
  end
end
