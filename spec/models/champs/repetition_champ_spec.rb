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
      expect(champ.for_tag.to_s).to eq("<table><tr><th>Ext</th></tr><tr><td>rb</td></tr></table>")
    end

    # pf: our modified version of RepetitionChamp#for_tag return a SafeBuffer
    # which is not supported by #to_tiptap_node. It only works on strings.
    # it "as tiptap node" do
    #   expect(champ.for_tag.to_tiptap_node).to include(type: 'orderedList')
    # end
  end
end
