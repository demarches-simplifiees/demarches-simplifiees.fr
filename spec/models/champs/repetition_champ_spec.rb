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
  let(:champ) { dossier.project_champs_public.find(&:repetition?) }

  describe "#for_tag" do
    before do
      champ_for_update(champ.rows.first.first).update(value: "rb")
    end

    it "can render as string" do
      expect(champ.type_de_champ.champ_value_for_tag(champ).to_s).to eq(
        <<~TXT.strip
          Languages

          Ext : rb
        TXT
      )
    end

    it "as tiptap node" do
      expect(champ.type_de_champ.champ_value_for_tag(champ).to_tiptap_node).to include(type: 'orderedList')
    end
  end
end
