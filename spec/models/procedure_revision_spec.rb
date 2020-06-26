describe ProcedureRevision do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, :with_repetition) }
  let(:revision) { procedure.active_revision }
  let(:type_de_champ) { revision.types_de_champ.first }
  let(:type_de_champ_private) { revision.types_de_champ_private.first }
  let(:type_de_champ_repetition) do
    type_de_champ = revision.types_de_champ.repetition.first
    type_de_champ.update(stable_id: 3333)
    type_de_champ
  end

  before do
    RevisionsMigration.add_revisions(procedure)
  end

  describe '#add_type_de_champ' do
    it 'type_de_champ' do
      expect(revision.types_de_champ.size).to eq(2)
      revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text"
      })
      procedure.reload
      expect(revision.types_de_champ.size).to eq(3)
      expect(procedure.types_de_champ.size).to eq(3)
    end

    it 'type_de_champ_private' do
      expect(revision.types_de_champ_private.size).to eq(1)
      revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text",
        private: true
      })
      procedure.reload
      expect(revision.types_de_champ_private.size).to eq(2)
      expect(procedure.types_de_champ_private.size).to eq(2)
    end

    it 'type_de_champ_repetition' do
      expect(type_de_champ_repetition.types_de_champ.size).to eq(1)
      revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text",
        parent_id: type_de_champ_repetition.stable_id
      })
      type_de_champ_repetition.reload
      expect(type_de_champ_repetition.types_de_champ.size).to eq(2)
    end
  end

  describe '#move_type_de_champ' do
    let(:procedure) { create(:procedure, :with_type_de_champ, types_de_champ_count: 4) }
    let(:last_type_de_champ) { revision.types_de_champ.last }

    it 'move down' do
      expect(revision.types_de_champ.index(type_de_champ)).to eq(0)
      revision.move_type_de_champ(type_de_champ.stable_id, 2)
      revision.reload
      expect(revision.types_de_champ.index(type_de_champ)).to eq(2)
    end

    it 'move up' do
      expect(revision.types_de_champ.index(last_type_de_champ)).to eq(3)
      revision.move_type_de_champ(last_type_de_champ.stable_id, 0)
      revision.reload
      expect(revision.types_de_champ.index(last_type_de_champ)).to eq(0)
    end

    context 'repetition' do
      let(:procedure) { create(:procedure, :with_repetition) }
      let(:type_de_champ) { type_de_champ_repetition.types_de_champ.first }
      let(:last_type_de_champ) { type_de_champ_repetition.types_de_champ.last }

      before do
        revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un champ text",
          parent_id: type_de_champ_repetition.stable_id
        })
        revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un champ text",
          parent_id: type_de_champ_repetition.stable_id
        })
        type_de_champ_repetition.reload
      end

      it 'move down' do
        expect(type_de_champ_repetition.types_de_champ.index(type_de_champ)).to eq(0)
        revision.move_type_de_champ(type_de_champ.stable_id, 2)
        type_de_champ_repetition.reload
        expect(type_de_champ_repetition.types_de_champ.index(type_de_champ)).to eq(2)
      end

      it 'move up' do
        expect(type_de_champ_repetition.types_de_champ.index(last_type_de_champ)).to eq(2)
        revision.move_type_de_champ(last_type_de_champ.stable_id, 0)
        type_de_champ_repetition.reload
        expect(type_de_champ_repetition.types_de_champ.index(last_type_de_champ)).to eq(0)
      end
    end
  end

  describe '#remove_type_de_champ' do
    it 'type_de_champ' do
      expect(revision.types_de_champ.size).to eq(2)
      revision.remove_type_de_champ(type_de_champ.stable_id)
      procedure.reload
      expect(revision.types_de_champ.size).to eq(1)
      expect(procedure.types_de_champ.size).to eq(1)
    end

    it 'type_de_champ_private' do
      expect(revision.types_de_champ_private.size).to eq(1)
      revision.remove_type_de_champ(type_de_champ_private.stable_id)
      procedure.reload
      expect(revision.types_de_champ_private.size).to eq(0)
      expect(procedure.types_de_champ_private.size).to eq(0)
    end

    it 'type_de_champ_repetition' do
      expect(type_de_champ_repetition.types_de_champ.size).to eq(1)
      expect(revision.types_de_champ.size).to eq(2)
      revision.remove_type_de_champ(type_de_champ_repetition.types_de_champ.first.stable_id)
      procedure.reload
      type_de_champ_repetition.reload
      expect(type_de_champ_repetition.types_de_champ.size).to eq(0)
      expect(revision.types_de_champ.size).to eq(2)
      expect(procedure.types_de_champ.size).to eq(2)
    end
  end
end
