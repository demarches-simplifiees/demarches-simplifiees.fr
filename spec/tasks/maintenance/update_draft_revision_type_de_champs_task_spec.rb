# frozen_string_literal: true

module Maintenance
  RSpec.describe UpdateDraftRevisionTypeDeChampsTask do
    let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
    let(:types_de_champ_public) {
      [
        { type: :text, libelle: "Text", stable_id: 11, mandatory: true },
        { type: :number, libelle: "Number", description: "Old desc", stable_id: 12 },
        {
          type: :repetition, libelle: "Bloc", stable_id: 13, children: [
            { type: :text, libelle: "RepText", stable_id: 131, description: "Remove me", mandatory: true },
            { type: :number, libelle: "RepNum", stable_id: 132 }
          ]
        }
      ]
    }

    let(:csv) do
      <<~CSV
        demarche_id,id,new_libelle,new_description,new_required,new_position,delete_flag
        #{procedure.id},#{find_by_stable_id(12).to_typed_id},[NEW] Number,[NEW] Number desc,true,0,
        #{procedure.id},#{find_by_stable_id(13).to_typed_id},Bloc,[NEW] bloc desc,,1,
        #{procedure.id},#{find_by_stable_id(132).to_typed_id},[NEW] RepNum,,true,0,
        #{procedure.id},#{find_by_stable_id(131).to_typed_id},[NEW] RepText,,,1,
        #{procedure.id},#{find_by_stable_id(11).to_typed_id},[supp] Text,,,2,true
      CSV
    end

    let(:rows) do
      CSV.parse(csv, headers: true, skip_blanks: true).map(&:to_h)
    end

    describe "#process" do
      subject(:process) do
        rows.each { described_class.process(_1) }
        procedure.reload
      end

      it "updates the type de champ" do
        process

        tdc = find_by_stable_id(12)
        expect(tdc.revision_type_de_champ.position).to eq(0)
        expect(tdc.libelle).to eq("[NEW] Number")
        expect(tdc.description).to eq("[NEW] Number desc")
        expect(tdc.mandatory).to eq(true)

        tdc = find_by_stable_id(13)
        expect(tdc.revision_type_de_champ.position).to eq(1)
        expect(tdc.libelle).to eq("Bloc")
        expect(tdc.description).to eq("[NEW] bloc desc")
        expect(tdc.mandatory).to eq(false)

        tdc = find_by_stable_id(132)
        expect(tdc.revision_type_de_champ.position).to eq(0)
        expect(tdc.libelle).to eq("[NEW] RepNum")
        expect(tdc.mandatory).to eq(true)

        tdc = find_by_stable_id(131)
        expect(tdc.revision_type_de_champ.position).to eq(1)
        expect(tdc.libelle).to eq("[NEW] RepText")
        expect(tdc.description).to eq("")
        expect(tdc.mandatory).to eq(false)

        tdc = find_by_stable_id(11)
        expect(tdc.revision_type_de_champ.position).to eq(2)
        expect(tdc.libelle).to eq("[supp] Text")
        expect(tdc.mandatory).to eq(false)
      end
    end

    def find_by_stable_id(stable_id)
      procedure.draft_revision.types_de_champ.find { _1.stable_id == stable_id }
    end
  end
end
