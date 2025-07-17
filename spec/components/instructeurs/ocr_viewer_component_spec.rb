# frozen_string_literal: true

RSpec.describe Instructeurs::OCRViewerComponent, type: :component do
  let(:champ) { double('champ', value_json:, RIB?: rib, external_data_fetched?: external_data_fetched, external_error_present?: external_error_present) }
  let(:component) { described_class.new(champ:) }

  let(:value_json) { nil }
  let(:rib) { true }
  let(:external_data_fetched) { true }
  let(:external_error_present) { false }

  describe '#render?' do
    context 'nominal' do
      it { expect(component.render?).to be true }
    end

    context 'when the champ is not rib' do
      let(:rib) { false }

      it { expect(component.render?).to be false }
    end

    context 'when the data is not fetched' do
      let(:external_data_fetched) { false }

      it { expect(component.render?).to be false }
    end

    context 'when the are external errors' do
      let(:external_error_present) { true }

      it { expect(component.render?).to be false }
    end
  end

  describe '#formated_data' do
    subject { render_inline(component) }

    let(:full_data) do
      {
        'rib' => {
          'titulaire' => ['John Doe'],
          'iban' => 'FR7612345678901234567890123',
          'bic' => 'ABCD1234',
          'bank_name' => 'Banque de Test'
        }
      }
    end

    context 'when data is complete' do
      let(:value_json) { full_data }

      it 'returns formatted data' do
        expect(subject).to have_css('.champ-content', text: 'John Doe')
        expect(subject).to have_css('.champ-content', text: 'FR7612345678901234567890123')
        expect(subject).to have_css('.champ-content', text: 'ABCD1234')
        expect(subject).to have_css('.champ-content', text: 'Banque de Test')
      end
    end

    context 'when data is incomplete' do
      let(:value_json) do
        copy = full_data.dup
        copy['rib']['titulaire'] = nil
        copy
      end

      it 'returns formatted data with processing error' do
        expect(subject).to have_css('.fr-hint-text', text: 'donnée n’a pas pu être récupérée')
        expect(subject).to have_css('.champ-content', text: 'FR7612345678901234567890123')
      end
    end
  end
end
