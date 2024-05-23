describe PiecesJointesListConcern do
  describe '#pieces_jointes_list' do
    include Logic
    let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
    let(:types_de_champ_public) do
      [
        { type: :integer_number, stable_id: 900 },
        { type: :piece_justificative, libelle: "pj1", stable_id: 910 },
        { type: :piece_justificative, libelle: "pj-cond", stable_id: 911, condition: ds_eq(champ_value(900), constant(1)) },
        { type: :repetition, libelle: "Répétition", stable_id: 920, children: [{ type: :piece_justificative, libelle: "pj2", stable_id: 921 }] },
        { type: :titre_identite, libelle: "pj3", stable_id: 930 }
      ]
    end

    let(:types_de_champ_private) do
      [
        { type: :integer_number, stable_id: 950 },
        { type: :piece_justificative, libelle: "pj5", stable_id: 960 },
        { type: :piece_justificative, libelle: "pj-cond2", stable_id: 961, condition: ds_eq(champ_value(900), constant(1)) },
        { type: :repetition, libelle: "Répétition2", stable_id: 970, children: [{ type: :piece_justificative, libelle: "pj6", stable_id: 971 }] }
      ]
    end

    let(:types_de_champ) { procedure.active_revision.types_de_champ }
    def find_by_stable_id(stable_id) = types_de_champ.find { _1.stable_id == stable_id }

    let(:pj1) { find_by_stable_id(910) }
    let(:pjcond) { find_by_stable_id(911) }
    let(:repetition) { find_by_stable_id(920) }
    let(:pj2) { find_by_stable_id(921) }
    let(:pj3) { find_by_stable_id(930) }

    let(:pj5) { find_by_stable_id(960) }
    let(:pjcond2) { find_by_stable_id(961) }
    let(:repetition2) { find_by_stable_id(970) }
    let(:pj6) { find_by_stable_id(971) }

    it "returns the list of pieces jointes without conditional" do
      expect(procedure.public_wrapped_partionned_pjs.first).to match_array([[pj1], [pj2, repetition], [pj3]])
    end

    it "returns the list of pieces jointes having conditional" do
      expect(procedure.public_wrapped_partionned_pjs.second).to match_array([[pjcond]])
    end

    it "returns the list of pieces jointes with private, without parent repetition, without titre identite" do
      expect(procedure.exportables_pieces_jointes.map(&:libelle)).to match_array([pj1, pj2, pjcond, pj5, pjcond2, pj6].map(&:libelle))
    end
  end
end
