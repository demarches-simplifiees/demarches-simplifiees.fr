describe ProcedureRevision do
  let(:draft) { procedure.draft_revision }
  let(:type_de_champ_public) { draft.types_de_champ_public.first }
  let(:type_de_champ_private) { draft.types_de_champ_private.first }
  let(:type_de_champ_repetition) do
    repetition = draft.types_de_champ_public.repetition.first
    repetition.update(stable_id: 3333)
    repetition
  end

  describe '#add_type_de_champ' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, :with_repetition) }

    it 'type_de_champ' do
      expect(draft.types_de_champ_public.size).to eq(2)
      new_type_de_champ = draft.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text"
      })
      draft.reload
      expect(draft.types_de_champ_public.size).to eq(3)
      expect(draft.types_de_champ_public.last).to eq(new_type_de_champ)
      expect(draft.revision_types_de_champ_public.last.position).to eq(2)
      expect(draft.revision_types_de_champ_public.last.type_de_champ).to eq(new_type_de_champ)
    end

    it 'type_de_champ_private' do
      expect(draft.types_de_champ_private.size).to eq(1)
      draft.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text",
        private: true
      })
      draft.reload
      expect(draft.types_de_champ_private.size).to eq(2)
    end

    it 'type_de_champ_repetition' do
      expect(type_de_champ_repetition.types_de_champ.size).to eq(1)
      draft.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text",
        parent_id: type_de_champ_repetition.stable_id
      })
      expect(type_de_champ_repetition.types_de_champ.size).to eq(2)
    end
  end

  describe '#move_type_de_champ' do
    let(:procedure) { create(:procedure, :with_type_de_champ, types_de_champ_count: 4) }
    let(:last_type_de_champ) { draft.types_de_champ_public.last }

    context 'with 4 types de champ publiques' do
      it 'move down' do
        expect(draft.types_de_champ_public.index(type_de_champ_public)).to eq(0)
        type_de_champ_public.update(order_place: nil)
        draft.move_type_de_champ(type_de_champ_public.stable_id, 2)
        draft.reload
        expect(draft.types_de_champ_public.index(type_de_champ_public)).to eq(2)
        expect(draft.procedure.types_de_champ.index(type_de_champ_public)).to eq(2)
        expect(draft.procedure.types_de_champ_for_procedure_presentation.not_repetition.index(type_de_champ_public)).to eq(2)
      end

      it 'move up' do
        expect(draft.types_de_champ_public.index(last_type_de_champ)).to eq(3)
        last_type_de_champ.update(order_place: nil)
        draft.move_type_de_champ(last_type_de_champ.stable_id, 0)
        draft.reload
        expect(draft.types_de_champ_public.index(last_type_de_champ)).to eq(0)
        expect(draft.procedure.types_de_champ.index(last_type_de_champ)).to eq(0)
        expect(draft.procedure.types_de_champ_for_procedure_presentation.not_repetition.index(last_type_de_champ)).to eq(0)
      end
    end

    context 'with a champ repetition repetition' do
      let(:procedure) { create(:procedure, :with_repetition) }

      let!(:second_child) do
        draft.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "second child",
          parent_id: type_de_champ_repetition.stable_id
        })
      end

      let!(:last_child) do
        draft.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "last child",
          parent_id: type_de_champ_repetition.stable_id
        })
      end

      it 'move down' do
        expect(type_de_champ_repetition.types_de_champ.index(second_child)).to eq(1)
        draft.move_type_de_champ(second_child.stable_id, 2)
        type_de_champ_repetition.reload
        expect(type_de_champ_repetition.types_de_champ.index(second_child)).to eq(2)
      end

      it 'move up' do
        expect(type_de_champ_repetition.types_de_champ.index(last_child)).to eq(2)
        draft.move_type_de_champ(last_child.stable_id, 0)
        type_de_champ_repetition.reload
        expect(type_de_champ_repetition.types_de_champ.index(last_child)).to eq(0)
      end
    end
  end

  describe '#remove_type_de_champ' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, :with_repetition) }

    it 'type_de_champ' do
      draft.remove_type_de_champ(type_de_champ_public.stable_id)

      expect(draft.types_de_champ_public.size).to eq(1)
    end

    it 'type_de_champ_private' do
      draft.remove_type_de_champ(type_de_champ_private.stable_id)

      expect(draft.types_de_champ_private.size).to eq(0)
    end

    it 'type_de_champ_repetition' do
      draft.remove_type_de_champ(type_de_champ_repetition.types_de_champ.first.stable_id)

      expect(type_de_champ_repetition.types_de_champ.size).to eq(0)
      expect(draft.types_de_champ_public.size).to eq(2)
    end
  end

  describe '#create_new_revision' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, :with_repetition) }
    let(:new_draft) { procedure.create_new_revision }

    before { new_draft.save }

    it 'should be part of procedure' do
      expect(new_draft.procedure).to eq(draft.procedure)
      expect(procedure.revisions.count).to eq(2)
      expect(procedure.revisions).to eq([draft, new_draft])
    end

    it 'should have types_de_champ' do
      expect(new_draft.types_de_champ_public.count).to eq(2)
      expect(new_draft.types_de_champ_private.count).to eq(1)
      expect(new_draft.types_de_champ_public).to eq(draft.types_de_champ_public)
      expect(new_draft.types_de_champ_private).to eq(draft.types_de_champ_private)

      expect(new_draft.revision_types_de_champ_public.count).to eq(2)
      expect(new_draft.revision_types_de_champ_private.count).to eq(1)
      expect(new_draft.revision_types_de_champ_public.count).to eq(draft.revision_types_de_champ_public.count)
      expect(new_draft.revision_types_de_champ_private.count).to eq(draft.revision_types_de_champ_private.count)
      expect(new_draft.revision_types_de_champ_public).not_to eq(draft.revision_types_de_champ_public)
      expect(new_draft.revision_types_de_champ_private).not_to eq(draft.revision_types_de_champ_private)
    end

    describe '#compare' do
      let(:type_de_champ_first) { draft.types_de_champ_public.first }
      let(:type_de_champ_second) { draft.types_de_champ_public.second }

      it 'type_de_champ' do
        expect(new_draft.types_de_champ_public.size).to eq(2)
        new_type_de_champ = new_draft.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un champ text"
        })
        draft.reload
        new_draft.reload
        expect(new_draft.types_de_champ_public.size).to eq(3)
        expect(new_draft.types_de_champ_public.last).to eq(new_type_de_champ)
        expect(new_draft.revision_types_de_champ_public.last.position).to eq(2)
        expect(new_draft.revision_types_de_champ_public.last.type_de_champ).to eq(new_type_de_champ)
        expect(new_draft.revision_types_de_champ_public.last.type_de_champ.revision).to eq(new_draft)
        expect(procedure.active_revision.different_from?(new_draft)).to be_truthy
        expect(procedure.active_revision.compare(new_draft)).to eq([
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          }
        ])

        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.first.stable_id).update(libelle: 'modifier le libelle')
        expect(procedure.active_revision.compare(new_draft.reload)).to eq([
          {
            model: :type_de_champ,
            op: :update,
            attribute: :libelle,
            label: type_de_champ_first.libelle,
            private: false,
            from: type_de_champ_first.libelle,
            to: "modifier le libelle",
            stable_id: type_de_champ_first.stable_id
          },
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          }
        ])
        expect(new_draft.types_de_champ_public.first.revision).to eq(new_draft)

        new_draft.move_type_de_champ(new_draft.types_de_champ_public.second.stable_id, 2)
        expect(procedure.active_revision.compare(new_draft.reload)).to eq([
          {
            model: :type_de_champ,
            op: :update,
            attribute: :libelle,
            label: type_de_champ_first.libelle,
            private: false,
            from: type_de_champ_first.libelle,
            to: "modifier le libelle",
            stable_id: type_de_champ_first.stable_id
          },
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          },
          {
            model: :type_de_champ,
            op: :move,
            label: type_de_champ_second.libelle,
            private: false,
            from: 1,
            to: 2,
            stable_id: type_de_champ_second.stable_id
          }
        ])
        expect(new_draft.types_de_champ_public.last.revision).to eq(draft)

        new_draft.remove_type_de_champ(new_draft.types_de_champ_public.first.stable_id)
        expect(procedure.active_revision.compare(new_draft.reload)).to eq([
          {
            model: :type_de_champ,
            op: :remove,
            label: type_de_champ_first.libelle,
            private: false,
            stable_id: type_de_champ_first.stable_id
          },
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          }
        ])

        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.last.stable_id).update(description: 'une description')
        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.last.stable_id).update(mandatory: true)
        expect(procedure.active_revision.compare(new_draft.reload)).to eq([
          {
            model: :type_de_champ,
            op: :remove,
            label: type_de_champ_first.libelle,
            private: false,
            stable_id: type_de_champ_first.stable_id
          },
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :description,
            label: type_de_champ_second.libelle,
            private: false,
            from: type_de_champ_second.description,
            to: "une description",
            stable_id: type_de_champ_second.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :mandatory,
            label: type_de_champ_second.libelle,
            private: false,
            from: false,
            to: true,
            stable_id: type_de_champ_second.stable_id
          }
        ])

        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.last.types_de_champ.first.stable_id).update(type_champ: :drop_down_list)
        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.last.types_de_champ.first.stable_id).update(drop_down_options: ['one', 'two'])
        expect(procedure.active_revision.compare(new_draft.reload)).to eq([
          {
            model: :type_de_champ,
            op: :remove,
            label: type_de_champ_first.libelle,
            private: false,
            stable_id: type_de_champ_first.stable_id
          },
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :description,
            label: type_de_champ_second.libelle,
            private: false,
            from: type_de_champ_second.description,
            to: "une description",
            stable_id: type_de_champ_second.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :mandatory,
            label: type_de_champ_second.libelle,
            private: false,
            from: false,
            to: true,
            stable_id: type_de_champ_second.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :type_champ,
            label: "sub type de champ",
            private: false,
            from: "text",
            to: "drop_down_list",
            stable_id: new_draft.types_de_champ_public.last.types_de_champ.first.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :drop_down_options,
            label: "sub type de champ",
            private: false,
            from: [],
            to: ["one", "two"],
            stable_id: new_draft.types_de_champ_public.last.types_de_champ.first.stable_id
          }
        ])

        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.last.types_de_champ.first.stable_id).update(type_champ: :carte)
        new_draft.find_or_clone_type_de_champ(new_draft.types_de_champ_public.last.types_de_champ.first.stable_id).update(options: { cadastres: true, znieff: true })
        expect(procedure.active_revision.compare(new_draft.reload)).to eq([
          {
            model: :type_de_champ,
            op: :remove,
            label: type_de_champ_first.libelle,
            private: false,
            stable_id: type_de_champ_first.stable_id
          },
          {
            model: :type_de_champ,
            op: :add,
            label: "Un champ text",
            private: false,
            stable_id: new_type_de_champ.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :description,
            label: type_de_champ_second.libelle,
            private: false,
            from: type_de_champ_second.description,
            to: "une description",
            stable_id: type_de_champ_second.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :mandatory,
            label: type_de_champ_second.libelle,
            private: false,
            from: false,
            to: true,
            stable_id: type_de_champ_second.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :type_champ,
            label: "sub type de champ",
            private: false,
            from: "text",
            to: "carte",
            stable_id: new_draft.types_de_champ_public.last.types_de_champ.first.stable_id
          },
          {
            model: :type_de_champ,
            op: :update,
            attribute: :carte_layers,
            label: "sub type de champ",
            private: false,
            from: [],
            to: [:cadastres, :znieff],
            stable_id: new_draft.types_de_champ_public.last.types_de_champ.first.stable_id
          }
        ])
      end
    end
  end
end
