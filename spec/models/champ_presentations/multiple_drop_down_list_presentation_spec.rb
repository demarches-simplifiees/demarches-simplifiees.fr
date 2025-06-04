# frozen_string_literal: true

describe ChampPresentations::MultipleDropDownListPresentation do
  let(:options) { ["Option 1", "Option 2", "Option 3"] }
  let(:representation) { described_class.new(options) }

  describe '#to_s' do
    it 'returns a comma-separated string of options' do
      expect(representation.to_s).to eq("Option 1, Option 2, Option 3")
    end
  end

  describe '#to_tiptap_node' do
    it 'returns the correct node structure' do
      expected_node = {
        type: "bulletList",
        content: [
          { content: [{ content: [{ :text => "Option 1", type: "text" }], type: "paragraph" }], type: "listItem" },
          { content: [{ content: [{ :text => "Option 2", type: "text" }], type: "paragraph" }], type: "listItem" },
          { content: [{ content: [{ :text => "Option 3", type: "text" }], type: "paragraph" }], type: "listItem" }
        ]
      }

      expect(representation.to_tiptap_node).to eq(expected_node)
    end
  end
end
