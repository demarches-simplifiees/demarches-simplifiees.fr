# frozen_string_literal: true

describe EditableChamp::DropDownListComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:tdc) { procedure.active_revision.types_de_champ.first }
  let(:champ) { dossier.champs.first }

  subject(:render) do
    component = nil
    ActionView::Base.empty.form_for(champ, url: '/') do |form|
      component = EditableChamp::EditableChampComponent.new(champ:, form:)
    end

    render_inline(component)
  end

  let(:fieldset) { page.find('fieldset') }
  let(:radios) { fieldset.all('input[type="radio"]') }
  def aria_labelledby(el) = el['aria-labelledby']&.split
  def aria_describedby(el) = el['aria-describedby']&.split

  describe 'with radio buttons' do
    def no_aria_on_radio? = radios.all? { aria_labelledby(_1).nil? && aria_describedby(_1).nil? }

    context 'when the champ has a description' do
      it do
        render

        expect(aria_labelledby(fieldset)).to eq([champ.labelledby_id, champ.describedby_id])
        expect(no_aria_on_radio?).to be true
      end

      context 'and the champ has an error' do
        before { champ.errors.add(:value, 'error') }

        it do
          render

          expect(aria_labelledby(fieldset)).to eq([champ.labelledby_id, champ.describedby_id, champ.error_id])
          expect(no_aria_on_radio?).to be true
        end
      end
    end

    context 'when the champ has no description' do
      before { tdc.update!(description: nil) }

      it do
        render

        expect(aria_labelledby(fieldset)).to eq([champ.labelledby_id])
        expect(no_aria_on_radio?).to be true
      end

      context 'and the champ has an error' do
        before { champ.errors.add(:value, 'error') }

        it do
          render

          expect(aria_labelledby(fieldset)).to eq([champ.labelledby_id, champ.error_id])
          expect(no_aria_on_radio?).to be true
        end
      end
    end
  end

  describe 'with select' do
    before { tdc.update!(drop_down_options: ('a'..'f').to_a) }
    let(:select) { page.find('select') }

    it do
      render
      expect(page.all('fieldset')).to be_empty
    end

    describe 'aria-describedby' do
      subject { render; aria_describedby(select) }

      context 'when the champ has a description' do
        it { is_expected.to eq([champ.describedby_id]) }

        context 'and the champ has an error' do
          before { champ.errors.add(:value, 'error') }

          it { is_expected.to eq([champ.describedby_id, champ.error_id]) }
        end
      end

      context 'when the champ has no description' do
        before { tdc.update!(description: nil) }

        it { is_expected.to be_nil }

        context 'and the champ has an error' do
          before { champ.errors.add(:value, 'error') }

          it { is_expected.to eq([champ.error_id]) }
        end
      end
    end
  end

  describe 'with a combobox' do
    before { tdc.update!(drop_down_options: ('a'..'z').to_a) }
    let(:select) { page.find('select') }
    let(:react_component) { page.find('react-component') }
    let(:react_props) { JSON.parse(react_component['props']) }

    it do
      render
      expect(page.all('fieldset')).to be_empty
    end

    describe 'aria-describedby' do
      subject { render; react_props['aria-describedby']&.split }

      context 'when the champ has a description' do
        it { is_expected.to eq([champ.describedby_id]) }

        context 'and the champ has an error' do
          before { champ.errors.add(:value, 'error') }

          it { is_expected.to eq([champ.describedby_id, champ.error_id]) }
        end
      end

      context 'when the champ has no description' do
        before { tdc.update!(description: nil) }

        it { is_expected.to be_nil }

        context 'and the champ has an error' do
          before { champ.errors.add(:value, 'error') }

          it { is_expected.to eq([champ.error_id]) }
        end
      end
    end
  end
end
