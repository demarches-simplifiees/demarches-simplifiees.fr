# frozen_string_literal: true

describe Procedure::ImportComponent, type: :component do
  let(:component) { described_class.new(procedure: procedures.individual) }

  describe '#contact_informations_template_detail' do
    it 'reads the extension and size without opening the file' do
      allow(File).to receive(:open).and_call_original
      size = Rails.public_path.join('csv/import-contact-informations-test.csv').size

      expect(component.contact_informations_template_detail).to eq("CSV – #{component.number_to_human_size(size)}")
      expect(File).not_to have_received(:open)
    end
  end
end
