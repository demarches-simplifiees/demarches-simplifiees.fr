# frozen_string_literal: true

describe ProcedureRevisionPreloader do
  let(:procedure) do
    create(:procedure, :published,
           types_de_champ_public: [
             { type: :integer_number },
             { type: :decimal_number }
           ],
           types_de_champ_private: [
             { type: :text },
             { type: :textarea }
           ])
  end

  describe '.load_one' do
    let(:revision) { procedure.draft_revision }
    subject { ProcedureRevisionPreloader.load_one(revision) }

    it 'assigns stuffs correctly' do
      # check it changes loaded from false to true
      expect { subject }.to change { procedure.draft_revision.association(:revision_types_de_champ).loaded? }.from(false).to(true)

      # check nested relationship
      expect(revision.revision_types_de_champ.first.association(:revision).loaded?).to eq(true)
      expect(revision.revision_types_de_champ.first.association(:procedure).loaded?).to eq(true)

      # check order
      original = Procedure.find(procedure.id)
      expect_relation_is_preloaded_sorted(original, procedure, :revision_types_de_champ)
      expect_relation_is_preloaded_sorted(original, procedure, :revision_types_de_champ_public)
      expect_relation_is_preloaded_sorted(original, procedure, :revision_types_de_champ_private)
      expect_relation_is_preloaded_sorted(original, procedure, :types_de_champ)
      expect_relation_is_preloaded_sorted(original, procedure, :types_de_champ_public)
      expect_relation_is_preloaded_sorted(original, procedure, :types_de_champ_private)
    end

    def expect_relation_is_preloaded_sorted(original, preloaded, association)
      expect(original.draft_revision.send(association).map(&:id)).to eq(preloaded.draft_revision.send(association).map(&:id))
    end
  end
end
