# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dossiers::ExportDropdownComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  describe '#include_archived_title' do
    let(:procedure) { double('Procedure') }

    context 'when archived_count is greater than 1' do
      it 'returns the pluralized archived title' do
        component = Dossiers::ExportDropdownComponent.new(
          procedure: procedure,
          archived_count: 3
        )
        expect(component.include_archived_title).to eq("<span>Inclure les <strong>3 dossiers « archivés »</strong></span>")
      end
    end

    context 'when archived_count is 1 or less' do
      it 'returns the singular archived title' do
        component = Dossiers::ExportDropdownComponent.new(
          procedure: procedure,
          archived_count: 1
        )
        expect(component.include_archived_title).to eq("<span>Inclure le <strong>dossier « archivé »</strong></span>")
      end
    end
  end
end
