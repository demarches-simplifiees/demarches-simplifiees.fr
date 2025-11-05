# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReferentielAutocompleteRenderService do
  let(:referentiel) { create(:api_referentiel, :autocomplete, datasource: '$.items') }
  let(:api_response) do
    {
      'items' => [
        { 'finess' => 'Tango', 'ej_rs' => 'Charlie' },
        { 'finess' => 'Bob', 'ej_rs' => 'Delta' },
      ],
    }
  end

  let(:subject) { described_class.new(api_response, referentiel) }

  describe '.format_response' do
    it 'formats the response for autocomplete' do
      expect(subject.format_response).to match_array([
        {
          label: 'Tango (Charlie)',
          value: 'Tango (Charlie)',
          data: anything,
        },
        {
          label: 'Bob (Delta)',
          value: 'Bob (Delta)',
          data: anything,
        },
      ])
    end
  end

  describe '.render_template' do
    it 'generates plain text from the template and the object' do
      obj = {
        'finess' => 'Tango',
        'ej_rs' => "Charlie",
      }
      expect(
        subject.send(:render_template, referentiel.json_template, obj).join('')
      ).to include('Tango (Charlie)')
    end
  end
end
