RSpec.describe TypesDeChampEditor::HeaderSectionComponent, type: :component do
  include ActionView::Context
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  let(:component) do
    cmp = nil
    form_for(tdc, url: '/') do |form|
      cmp = described_class.new(form: form, tdc: tdc, upper_tdcs: upper_tdcs)
    end
    cmp
  end
  subject { render_inline(component).to_html }

  describe 'header_section_options_for_select' do
    context 'without upper tdc' do
      let(:tdc) { header.type_de_champ }
      let(:header) { build(:champ_header_section) }
      let(:upper_tdcs) { [] }

      it 'allows up to level 1 header section' do
        expect(subject).to have_selector("option", count: 1)
      end
    end

    context 'with upper tdc of level 1' do
      let(:tdc) { header.type_de_champ }
      let(:header) { build(:champ_header_section_level_1) }
      let(:upper_tdcs) { [build(:champ_header_section_level_1).type_de_champ] }

      it 'allows up to level 2 header section' do
        expect(subject).to have_selector("option", count: 2)
      end
    end

    context 'with upper tdc of level 2' do
      let(:tdc) { header.type_de_champ }
      let(:header) { build(:champ_header_section_level_1) }
      let(:upper_tdcs) { [build(:champ_header_section_level_1), build(:champ_header_section_level_2)].map(&:type_de_champ) }

      it 'allows up to level 3 header section' do
        expect(subject).to have_selector("option", count: 3)
      end
    end

    context 'with upper tdc of level 3' do
      let(:tdc) { header.type_de_champ }
      let(:header) { build(:champ_header_section_level_1) }
      let(:upper_tdcs) do
        [
          build(:champ_header_section_level_1),
          build(:champ_header_section_level_2),
          build(:champ_header_section_level_3)
        ].map(&:type_de_champ)
      end

      it 'reaches limit of at most 3 section level' do
        expect(subject).to have_selector("option", count: 3)
      end
    end

    context 'with error' do
      let(:tdc) { header.type_de_champ }
      let(:header) { build(:champ_header_section_level_2) }
      let(:upper_tdcs) { [] }

      it 'includes disabled levels' do
        expect(subject).to have_selector("option", count: 3)
        expect(subject).to have_selector("option[disabled]", count: 2)
      end
    end
  end

  describe 'errors' do
    let(:tdc) { header.type_de_champ }
    let(:header) { build(:champ_header_section_level_2) }
    let(:upper_tdcs) { [] }

    it 'returns errors' do
      expect(subject).to have_selector('.errors-summary')
    end
  end
end
