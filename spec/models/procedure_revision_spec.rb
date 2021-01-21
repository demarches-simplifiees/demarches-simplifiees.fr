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

  describe '#add_type_de_champ' do
    it 'type_de_champ' do
      expect(revision.types_de_champ.size).to eq(2)
      new_type_de_champ = revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text"
      })
      revision.reload
      expect(revision.types_de_champ.size).to eq(3)
      expect(revision.types_de_champ.last).to eq(new_type_de_champ)
      expect(revision.revision_types_de_champ.last.position).to eq(2)
      expect(revision.revision_types_de_champ.last.type_de_champ).to eq(new_type_de_champ)
    end

    it 'type_de_champ_private' do
      expect(revision.types_de_champ_private.size).to eq(1)
      revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text",
        private: true
      })
      revision.reload
      expect(revision.types_de_champ_private.size).to eq(2)
    end

    it 'type_de_champ_repetition' do
      expect(type_de_champ_repetition.types_de_champ.size).to eq(1)
      revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text",
        parent_id: type_de_champ_repetition.stable_id
      })
      expect(type_de_champ_repetition.types_de_champ.size).to eq(2)
    end
  end

  describe '#move_type_de_champ' do
    let(:procedure) { create(:procedure, :with_type_de_champ, types_de_champ_count: 4) }
    let(:last_type_de_champ) { revision.types_de_champ.last }

    it 'move down' do
      expect(revision.types_de_champ.index(type_de_champ)).to eq(0)
      type_de_champ.update(order_place: nil)
      revision.move_type_de_champ(type_de_champ.stable_id, 2)
      revision.reload
      expect(revision.types_de_champ.index(type_de_champ)).to eq(2)
      expect(revision.procedure.types_de_champ.index(type_de_champ)).to eq(2)
      expect(revision.procedure.types_de_champ_for_export.index(type_de_champ)).to eq(2)
    end

    it 'move up' do
      expect(revision.types_de_champ.index(last_type_de_champ)).to eq(3)
      last_type_de_champ.update(order_place: nil)
      revision.move_type_de_champ(last_type_de_champ.stable_id, 0)
      revision.reload
      expect(revision.types_de_champ.index(last_type_de_champ)).to eq(0)
      expect(revision.procedure.types_de_champ.index(last_type_de_champ)).to eq(0)
      expect(revision.procedure.types_de_champ_for_export.index(last_type_de_champ)).to eq(0)
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
    end

    it 'type_de_champ_private' do
      expect(revision.types_de_champ_private.size).to eq(1)
      revision.remove_type_de_champ(type_de_champ_private.stable_id)
      expect(revision.types_de_champ_private.size).to eq(0)
    end

    it 'type_de_champ_repetition' do
      expect(type_de_champ_repetition.types_de_champ.size).to eq(1)
      expect(revision.types_de_champ.size).to eq(2)
      revision.remove_type_de_champ(type_de_champ_repetition.types_de_champ.first.stable_id)
      type_de_champ_repetition.reload
      expect(type_de_champ_repetition.types_de_champ.size).to eq(0)
      expect(revision.types_de_champ.size).to eq(2)
    end
  end

  describe '#create_new_revision' do
    let(:new_revision) { procedure.create_new_revision }

    before { new_revision.save }

    it 'should be part of procedure' do
      expect(new_revision.procedure).to eq(revision.procedure)
      expect(procedure.revisions.count).to eq(2)
      expect(procedure.revisions).to eq([revision, new_revision])
    end

    it 'should have types_de_champ' do
      expect(new_revision.types_de_champ.count).to eq(2)
      expect(new_revision.types_de_champ_private.count).to eq(1)
      expect(new_revision.types_de_champ).to eq(revision.types_de_champ)
      expect(new_revision.types_de_champ_private).to eq(revision.types_de_champ_private)

      expect(new_revision.revision_types_de_champ.count).to eq(2)
      expect(new_revision.revision_types_de_champ_private.count).to eq(1)
      expect(new_revision.revision_types_de_champ.count).to eq(revision.revision_types_de_champ.count)
      expect(new_revision.revision_types_de_champ_private.count).to eq(revision.revision_types_de_champ_private.count)
      expect(new_revision.revision_types_de_champ).not_to eq(revision.revision_types_de_champ)
      expect(new_revision.revision_types_de_champ_private).not_to eq(revision.revision_types_de_champ_private)
    end

    describe '#compare' do
      let(:type_de_champ_first) { revision.types_de_champ.first }
      let(:type_de_champ_second) { revision.types_de_champ.second }

      it 'type_de_champ' do
        expect(new_revision.types_de_champ.size).to eq(2)
        new_type_de_champ = new_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un champ text"
        })
        revision.reload
        expect(new_revision.types_de_champ.size).to eq(3)
        expect(new_revision.types_de_champ.last).to eq(new_type_de_champ)
        expect(new_revision.revision_types_de_champ.last.position).to eq(2)
        expect(new_revision.revision_types_de_champ.last.type_de_champ).to eq(new_type_de_champ)
        expect(new_revision.revision_types_de_champ.last.type_de_champ.revision).to eq(new_revision)
        expect(procedure.active_revision.changed?(new_revision)).to be_truthy
        expect(procedure.active_revision.compare(new_revision)).to eq([
          {
            op: :add,
            label: "Un champ text"
          }
        ])

        new_revision.find_or_clone_type_de_champ(new_revision.types_de_champ.first.stable_id).update(libelle: 'modifier le libelle')
        expect(procedure.active_revision.compare(new_revision.reload)).to eq([
          {
            op: :update,
            attribute: :libelle,
            label: type_de_champ_first.libelle,
            from: type_de_champ_first.libelle,
            to: "modifier le libelle"
          },
          {
            op: :add,
            label: "Un champ text"
          }
        ])
        expect(new_revision.types_de_champ.first.revision).to eq(new_revision)

        new_revision.move_type_de_champ(new_revision.types_de_champ.second.stable_id, 2)
        expect(procedure.active_revision.compare(new_revision.reload)).to eq([
          {
            op: :update,
            attribute: :libelle,
            label: type_de_champ_first.libelle,
            from: type_de_champ_first.libelle,
            to: "modifier le libelle"
          },
          {
            op: :add,
            label: "Un champ text"
          },
          {
            op: :move,
            label: type_de_champ_second.libelle,
            from: 1,
            to: 2
          }
        ])
        expect(new_revision.types_de_champ.last.revision).to eq(revision)

        new_revision.remove_type_de_champ(new_revision.types_de_champ.first.stable_id)
        expect(procedure.active_revision.compare(new_revision.reload)).to eq([
          {
            op: :remove,
            label: type_de_champ_first.libelle
          },
          {
            op: :add,
            label: "Un champ text"
          }
        ])

        new_revision.find_or_clone_type_de_champ(new_revision.types_de_champ.last.stable_id).update(description: 'une description')
        new_revision.find_or_clone_type_de_champ(new_revision.types_de_champ.last.stable_id).update(mandatory: true)
        expect(procedure.active_revision.compare(new_revision.reload)).to eq([
          {
            op: :remove,
            label: type_de_champ_first.libelle
          },
          {
            op: :add,
            label: "Un champ text"
          },
          {
            op: :update,
            attribute: :description,
            label: type_de_champ_second.libelle,
            from: type_de_champ_second.description,
            to: "une description"
          },
          {
            op: :update,
            attribute: :mandatory,
            label: type_de_champ_second.libelle,
            from: false,
            to: true
          }
        ])

        new_revision.find_or_clone_type_de_champ(new_revision.types_de_champ.last.types_de_champ.first.stable_id).update(type_champ: :drop_down_list)
        new_revision.find_or_clone_type_de_champ(new_revision.types_de_champ.last.types_de_champ.first.stable_id).update(drop_down_options: ['one', 'two'])
        expect(procedure.active_revision.compare(new_revision.reload)).to eq([
          {
            op: :remove,
            label: type_de_champ_first.libelle
          },
          {
            op: :add,
            label: "Un champ text"
          },
          {
            op: :update,
            attribute: :description,
            label: type_de_champ_second.libelle,
            from: type_de_champ_second.description,
            to: "une description"
          },
          {
            op: :update,
            attribute: :mandatory,
            label: type_de_champ_second.libelle,
            from: false,
            to: true
          },
          {
            op: :update,
            attribute: :type_champ,
            label: "sub type de champ",
            from: "text",
            to: "drop_down_list"
          },
          {
            op: :update,
            attribute: :drop_down_options,
            label: "sub type de champ",
            from: [],
            to: ["one", "two"]
          }
        ])
      end
    end
  end
end
