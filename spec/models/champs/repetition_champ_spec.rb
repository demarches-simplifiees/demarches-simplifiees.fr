# frozen_string_literal: true

describe Champs::RepetitionChamp do
  let(:procedure) {
    create(:procedure,
      types_de_champ_public: [
        {
          type: :repetition,
          children: [{ type: :text, libelle: "Ext" }], libelle: "Languages"
        }
      ])
  }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }

  describe "#for_tag" do
    before do
      champ.rows[0][0].update(value: "rb")
    end

    it "can render as string" do
      expect(champ.for_tag.to_s).to eq(
        <<~TXT.strip
          Languages

          Ext : rb
        TXT
      )
    end

    it "as tiptap node" do
      expect(champ.for_tag.to_tiptap_node).to include(type: 'orderedList')
    end
  end
end
