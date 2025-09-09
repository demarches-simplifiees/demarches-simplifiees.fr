# frozen_string_literal: true

describe ProcedureRevision do
  let(:draft) { procedure.draft_revision }
  let(:type_de_champ_public) { draft.types_de_champ_public.first }
  let(:type_de_champ_private) { draft.types_de_champ_private.first }
  let(:type_de_champ_repetition) do
    repetition = draft.types_de_champ_public.find(&:repetition?)
    repetition.update(stable_id: 3333)
    repetition
  end

  describe '#add_type_de_champ' do
    # tdc: public: text, repetition ; private: text ; +1 text child of repetition
    let(:procedure) do
      create(:procedure,
            types_de_champ_public: [
              { type: :text, libelle: 'l1' },
              {
                type: :repetition, libelle: 'l2', children: [
                  { type: :text, libelle: 'l2' }
                ]
              }
            ],
            types_de_champ_private: [
              { type: :text, libelle: 'l1 private' }
            ])
    end
    let(:tdc_params) { text_params }
    let(:last_coordinate) { draft.revision_types_de_champ.last }

    subject { draft.add_type_de_champ(tdc_params) }

    context 'with a text tdc' do
      let(:text_params) { { type_champ: :text, libelle: 'text', after_stable_id: procedure.draft_revision.types_de_champ_public.last.stable_id } }

      it 'public' do
        expect { subject }.to change { draft.types_de_champ_public.size }.from(2).to(3)
        expect(draft.types_de_champ_public.last).to eq(subject)
        expect(draft.revision_types_de_champ_public.map(&:position)).to eq([0, 1, 2])

        expect(last_coordinate.position).to eq(2)
        expect(last_coordinate.type_de_champ).to eq(subject)
      end
    end

    context 'with a private tdc' do
      let(:text_params) { { type_champ: :text, libelle: 'text', after_stable_id: procedure.draft_revision.types_de_champ_private.last.id } }
      let(:tdc_params) { text_params.merge(private: true) }

      it 'private' do
        expect { subject }.to change { draft.types_de_champ_private.count }.from(1).to(2)
        expect(draft.types_de_champ_private.last).to eq(subject)
        expect(draft.revision_types_de_champ_private.map(&:position)).to eq([0, 1])
        expect(last_coordinate.position).to eq(1)
      end
    end

    context 'with a repetition child' do
      let(:text_params) { { type_champ: :text, libelle: 'text', after_stable_id: procedure.draft_revision.children_of(type_de_champ_repetition).last.stable_id } }
      let(:tdc_params) { text_params.merge(parent_stable_id: type_de_champ_repetition.stable_id) }

      it do
        expect { subject }.to change { draft.reload.types_de_champ.count }.from(4).to(5)
        expect(draft.children_of(type_de_champ_repetition).last).to eq(subject)
        expect(draft.children_of(type_de_champ_repetition).map { draft.coordinate_for(_1).position }).to eq([0, 1])

        expect(last_coordinate.position).to eq(1)

        parent_coordinate = draft.revision_types_de_champ.find_by(type_de_champ: type_de_champ_repetition)
        expect(last_coordinate.parent).to eq(parent_coordinate)
      end
    end

    context 'when a parent is incorrect' do
      let(:text_params) { { type_champ: :text, libelle: 'text', after_stable_id: procedure.draft_revision.types_de_champ_private.last.id } }
      let(:tdc_params) { text_params.merge(parent_id: 123456789) }

      it { expect(subject.errors.full_messages).not_to be_empty }
    end

    context 'after_stable_id' do
      context 'with a valid after_stable_id' do
        let(:text_params) { { type_champ: :text, libelle: 'text', after_stable_id: procedure.draft_revision.types_de_champ_private.last.id } }
        let(:tdc_params) { text_params.merge(after_stable_id: draft.revision_types_de_champ_public.first.stable_id, libelle: 'in the middle') }

        it do
          expect(draft.revision_types_de_champ_public.map(&:libelle)).to eq(['l1', 'l2'])
          subject
          expect(draft.revision_types_de_champ_public.map(&:libelle)).to eq(['l1', 'in the middle', 'l2'])
          expect(draft.revision_types_de_champ_public.map(&:position)).to eq([0, 1, 2])
        end
      end

      context 'with blank valid after_stable_id' do
        let(:text_params) { { type_champ: :text, libelle: 'text', after_stable_id: procedure.draft_revision.types_de_champ_private.last.id } }
        let(:tdc_params) { text_params.merge(after_stable_id: '', libelle: 'in the middle') }

        it do
          subject
          expect(draft.revision_types_de_champ_public.map(&:libelle)).to eq(['in the middle', 'l1', 'l2'])
        end
      end
    end
  end

  describe '#move_type_de_champ' do
    let(:procedure) { create(:procedure, types_de_champ_public: Array.new(4) { { type: :text } }) }
    let(:last_type_de_champ) { draft.types_de_champ_public.last }

    context 'with 4 types de champ publiques' do
      it 'move down' do
        expect(draft.types_de_champ_public.index(type_de_champ_public)).to eq(0)
        stable_id_before = draft.revision_types_de_champ_public.map(&:stable_id)
        draft.move_type_de_champ(type_de_champ_public.stable_id, 2)
        draft.reload
        expect(draft.revision_types_de_champ_public.map(&:position)).to eq([0, 1, 2, 3])
        expect(draft.types_de_champ_public.index(type_de_champ_public)).to eq(2)
        expect(draft.procedure.types_de_champ_for_procedure_export.index(type_de_champ_public)).to eq(2)
      end

      it 'move up' do
        expect(draft.types_de_champ_public.index(last_type_de_champ)).to eq(3)
        draft.move_type_de_champ(last_type_de_champ.stable_id, 0)
        draft.reload
        expect(draft.revision_types_de_champ_public.map(&:position)).to eq([0, 1, 2, 3])
        expect(draft.types_de_champ_public.index(last_type_de_champ)).to eq(0)
        expect(draft.procedure.types_de_champ_for_procedure_export.index(last_type_de_champ)).to eq(0)
      end
    end

    context 'with a champ repetition repetition' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text }, { type: :integer_number }] }]) }

      let!(:second_child) do
        draft.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "second child",
          parent_stable_id: type_de_champ_repetition.stable_id,
          after_stable_id: draft.reload.children_of(type_de_champ_repetition).last.stable_id
        })
      end

      let!(:last_child) do
        draft.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "last child",
          parent_stable_id: type_de_champ_repetition.stable_id,
          after_stable_id: draft.reload.children_of(type_de_champ_repetition).last.stable_id
        })
      end

      it 'move down' do
        expect(draft.children_of(type_de_champ_repetition).index(second_child)).to eq(2)

        draft.move_type_de_champ(second_child.stable_id, 3)

        expect(draft.children_of(type_de_champ_repetition).index(second_child)).to eq(3)
      end

      it 'move up' do
        expect(draft.children_of(type_de_champ_repetition).index(last_child)).to eq(3)

        draft.move_type_de_champ(last_child.stable_id, 0)

        expect(draft.children_of(type_de_champ_repetition).index(last_child)).to eq(0)
      end
    end
  end

  describe '#remove_type_de_champ' do
    context 'for a classic tdc' do
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

      it 'type_de_champ' do
        draft.remove_type_de_champ(type_de_champ_public.stable_id)

        expect(draft.types_de_champ_public).to be_empty
      end

      it 'type_de_champ_private' do
        draft.remove_type_de_champ(type_de_champ_private.stable_id)

        expect(draft.types_de_champ_private).to be_empty
      end
    end

    context 'with multiple tdc' do
      context 'in public tdc' do
        let(:procedure) { create(:procedure, types_de_champ_public: Array.new(3) { { type: :text } }) }

        it 'reorders' do
          expect(draft.revision_types_de_champ_public.pluck(:position)).to eq([0, 1, 2])

          first_stable_id = draft.types_de_champ_public[1].stable_id

          draft.remove_type_de_champ(first_stable_id)

          expect(draft.revision_types_de_champ_public.pluck(:position)).to eq([0, 1])

          expect { draft.remove_type_de_champ(first_stable_id) }.not_to raise_error
        end
      end

      context 'in repetition tdc' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text }, { type: :integer_number }] }]) }
        let!(:second_child) do
          draft.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "second child",
            parent_stable_id: type_de_champ_repetition.stable_id
          })
        end

        let!(:last_child) do
          draft.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "last child",
            parent_stable_id: type_de_champ_repetition.stable_id
          })
        end

        it 'reorders' do
          children = draft.coordinate_for(type_de_champ_repetition).revision_types_de_champ
          expect(children.map(&:position)).to eq([0, 1, 2, 3])

          draft.remove_type_de_champ(children[1].stable_id)

          children = draft.coordinate_for(type_de_champ_repetition).revision_types_de_champ
          expect(children.map(&:position)).to eq([0, 1, 2])
        end
      end
    end

    context 'for a type_de_champ_repetition' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text }, { type: :integer_number }] }]) }
      let!(:child) { child = draft.children_of(type_de_champ_repetition).first }

      it 'can remove its children' do
        draft.remove_type_de_champ(child.stable_id)

        expect { child.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(draft.types_de_champ_public.size).to eq(1)
      end

      it 'can remove the parent' do
        draft.remove_type_de_champ(type_de_champ_repetition.stable_id)

        expect { child.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { type_de_champ_repetition.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(draft.types_de_champ_public).to be_empty
      end

      context 'when there already is a revision with this child' do
        let!(:new_draft) { procedure.create_new_revision }

        it 'can remove its children only in the new revision' do
          new_draft.remove_type_de_champ(child.stable_id)

          expect { child.reload }.not_to raise_error
          expect(draft.children_of(type_de_champ_repetition).size).to eq(2)
          expect(new_draft.children_of(type_de_champ_repetition).size).to eq(1)
        end

        it 'can remove the parent only in the new revision' do
          new_draft.remove_type_de_champ(type_de_champ_repetition.stable_id)

          expect { child.reload }.not_to raise_error
          expect { type_de_champ_repetition.reload }.not_to raise_error
          expect(draft.types_de_champ_public.size).to eq(1)
          expect(new_draft.types_de_champ_public).to be_empty
        end
      end
    end
  end

  describe '#create_new_revision' do
    let(:new_draft) { procedure.create_new_revision }

    context 'from a simple procedure' do
      let(:procedure) { create(:procedure) }

      it 'should be part of procedure' do
        expect(new_draft.procedure).to eq(draft.procedure)
        expect(procedure.revisions.count).to eq(2)
        expect(procedure.revisions).to eq([draft, new_draft])
      end
    end

    context 'with simple tdc' do
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

      it 'should have the same tdcs with different links' do
        expect(new_draft.types_de_champ_public.count).to eq(1)
        expect(new_draft.types_de_champ_private.count).to eq(1)
        expect(new_draft.types_de_champ_public).to eq(draft.types_de_champ_public)
        expect(new_draft.types_de_champ_private).to eq(draft.types_de_champ_private)

        expect(new_draft.revision_types_de_champ_public.count).to eq(1)
        expect(new_draft.revision_types_de_champ_private.count).to eq(1)
        expect(new_draft.revision_types_de_champ_public).not_to eq(draft.revision_types_de_champ_public)
        expect(new_draft.revision_types_de_champ_private).not_to eq(draft.revision_types_de_champ_private)
      end
    end

    context 'with repetition_type_de_champ' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text }, { type: :integer_number }] }]) }

      it 'should have the same tdcs with different links' do
        expect(new_draft.types_de_champ.count).to eq(3)
        expect(new_draft.types_de_champ).to eq(draft.types_de_champ)

        new_repetition, new_child = new_draft.types_de_champ.partition(&:repetition?).map(&:first)

        parent = new_draft.revision_types_de_champ.find_by(type_de_champ: new_repetition)
        child = new_draft.revision_types_de_champ.find_by(type_de_champ: new_child)

        expect(child.parent_id).to eq(parent.id)
      end
    end
  end

  describe '#update_type_de_champ' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text }, { type: :integer_number }] }]) }
    let(:last_coordinate) { draft.revision_types_de_champ.last }
    let(:last_type_de_champ) { last_coordinate.type_de_champ }

    context 'bug with duplicated repetition child' do
      before do
        procedure.publish!
        procedure.reload
        draft.find_and_ensure_exclusive_use(last_type_de_champ.stable_id).update(libelle: 'new libelle')
        procedure.reload
        draft.reload
      end

      it do
        expect(procedure.revisions.size).to eq(2)
        expect(draft.revision_types_de_champ.where.not(parent_id: nil).size).to eq(2)
      end
    end
  end

  describe '#compare_types_de_champ' do
    include Logic
    let(:new_draft) { procedure.create_new_revision }
    subject { procedure.active_revision.compare_types_de_champ(new_draft.reload).map(&:to_h) }

    describe 'when tdcs changes' do
      let(:first_tdc) { draft.types_de_champ_public.first }
      let(:second_tdc) { draft.types_de_champ_public.second }

      context 'with a procedure with 2 tdcs' do
        let(:procedure) do
          create(:procedure, types_de_champ_public: [
            { type: :integer_number, libelle: 'l1' },
            { type: :text, libelle: 'l2' }
          ])
        end

        context 'when a condition is added' do
          before do
            second = new_draft.find_and_ensure_exclusive_use(second_tdc.stable_id)
            second.update(condition: ds_eq(champ_value(first_tdc.stable_id), constant(3)))
          end

          it do
            is_expected.to eq([
              {
                attribute: :condition,
                from: nil,
                label: "l2",
                op: :update,
                private: false,
                stable_id: second_tdc.stable_id,
                to: "(l1 == 3)"
              }
            ])
          end
        end

        context 'when a condition is removed' do
          before do
            second_tdc.update(condition: ds_eq(champ_value(first_tdc.stable_id), constant(2)))
            draft.reload

            second = new_draft.find_and_ensure_exclusive_use(second_tdc.stable_id)
            second.update(condition: nil)
          end

          it do
            is_expected.to eq([
              {
                attribute: :condition,
                from: "(l1 == 2)",
                label: "l2",
                op: :update,
                private: false,
                stable_id: second_tdc.stable_id,
                to: nil
              }
            ])
          end
        end

        context 'when a condition is changed' do
          before do
            second_tdc.update(condition: ds_eq(champ_value(first_tdc.stable_id), constant(2)))
            draft.reload

            second = new_draft.find_and_ensure_exclusive_use(second_tdc.stable_id)
            second.update(condition: ds_eq(champ_value(first_tdc.stable_id), constant(3)))
          end

          it do
            is_expected.to eq([
              {
                attribute: :condition,
                from: "(l1 == 2)",
                label: "l2",
                op: :update,
                private: false,
                stable_id: second_tdc.stable_id,
                to: "(l1 == 3)"
              }
            ])
          end
        end
      end

      context 'when a type de champ is added' do
        let(:procedure) { create(:procedure) }
        let(:new_tdc) do
          new_draft.add_type_de_champ(
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            mandatory: false,
            libelle: "Un champ text"
          )
        end

        before { new_tdc }

        it do
          is_expected.to eq([
            {
              op: :add,
              label: "Un champ text",
              private: false,
              mandatory: false,
              stable_id: new_tdc.stable_id
            }
          ])
        end
      end

      context 'when a type de champ is changed' do
        context 'when libelle, description, and mandatory are changed' do
          let(:procedure) { create(:procedure, :with_type_de_champ) }

          before do
            updated_tdc = new_draft.find_and_ensure_exclusive_use(first_tdc.stable_id)

            updated_tdc.update(libelle: 'modifier le libelle', description: 'une description', mandatory: !updated_tdc.mandatory)
          end

          it do
            is_expected.to eq([
              {
                op: :update,
                attribute: :libelle,
                label: first_tdc.libelle,
                private: false,
                from: first_tdc.libelle,
                to: "modifier le libelle",
                stable_id: first_tdc.stable_id
              },
              {
                op: :update,
                attribute: :description,
                label: first_tdc.libelle,
                private: false,
                from: first_tdc.description,
                to: "une description",
                stable_id: first_tdc.stable_id
              },
              {
                op: :update,
                attribute: :mandatory,
                label: first_tdc.libelle,
                private: false,
                from: true,
                to: false,
                stable_id: first_tdc.stable_id
              }
            ])
          end
        end

        context 'when collapsible_explanation_enabled and collapsible_explanation_text are changed' do
          let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :explication }]) }

          before do
            updated_tdc = new_draft.find_and_ensure_exclusive_use(first_tdc.stable_id)

            updated_tdc.update(collapsible_explanation_enabled: "1", collapsible_explanation_text: 'afficher au clique')
          end
          it do
            is_expected.to eq([
              {
                op: :update,
                attribute: :collapsible_explanation_enabled,
                label: first_tdc.libelle,
                private: first_tdc.private?,
                from: false,
                to: true,
                stable_id: first_tdc.stable_id
              },
              {
                op: :update,
                attribute: :collapsible_explanation_text,
                label: first_tdc.libelle,
                private: first_tdc.private?,
                from: nil,
                to: 'afficher au clique',
                stable_id: first_tdc.stable_id
              }
            ])
          end
        end
      end

      context 'when a type de champ is transformed into a text_area with no character limit' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :text }]) }

        before do
          updated_tdc = new_draft.find_and_ensure_exclusive_use(first_tdc.stable_id)
          updated_tdc.update(type_champ: :textarea, options: { "character_limit" => "" })
        end

        it do
          is_expected.to eq([
            {
              op: :update,
              attribute: :type_champ,
              label: first_tdc.libelle,
              private: false,
              from: "text",
              to: "textarea",
              stable_id: first_tdc.stable_id
            }
          ])
        end
      end

      context 'when a type de champ is moved' do
        let(:procedure) { create(:procedure, types_de_champ_public: Array.new(3) { { type: :text } }) }
        let(:new_draft_second_tdc) { new_draft.types_de_champ_public.second }
        let(:new_draft_third_tdc) { new_draft.types_de_champ_public.third }

        before do
          new_draft_second_tdc
          new_draft_third_tdc
          new_draft.move_type_de_champ(new_draft_second_tdc.stable_id, 2)
        end

        it do
          is_expected.to eq([
            {
              op: :move,
              label: new_draft_third_tdc.libelle,
              private: false,
              from: 2,
              to: 1,
              stable_id: new_draft_third_tdc.stable_id
            },
            {
              op: :move,
              label: new_draft_second_tdc.libelle,
              private: false,
              from: 1,
              to: 2,
              stable_id: new_draft_second_tdc.stable_id
            }
          ])
        end
      end

      context 'when a type de champ is removed' do
        let(:procedure) { create(:procedure, :with_type_de_champ) }

        before do
          new_draft.remove_type_de_champ(first_tdc.stable_id)
        end

        it do
          is_expected.to eq([
            {
              op: :remove,
              label: first_tdc.libelle,
              private: false,
              stable_id: first_tdc.stable_id
            }
          ])
        end
      end

      context 'when a child type de champ is transformed into a drop_down_list' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text, libelle: 'sub type de champ' }, { type: :integer_number }] }]) }

        before do
          child = new_draft.children_of(new_draft.types_de_champ_public.last).first
          new_draft.find_and_ensure_exclusive_use(child.stable_id).update(type_champ: :drop_down_list, drop_down_options: ['one', 'two'])
        end

        it do
          is_expected.to eq([
            {
              op: :update,
              attribute: :type_champ,
              label: "sub type de champ",
              private: false,
              from: "text",
              to: "drop_down_list",
              stable_id: new_draft.children_of(new_draft.types_de_champ_public.last).first.stable_id
            },
            {
              op: :update,
              attribute: :drop_down_options,
              label: "sub type de champ",
              private: false,
              from: [],
              to: ["one", "two"],
              stable_id: new_draft.children_of(new_draft.types_de_champ_public.last).first.stable_id
            }
          ])
        end
      end

      context 'when a child type de champ is transformed into a map' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text, libelle: 'sub type de champ' }, { type: :integer_number }] }]) }

        before do
          child = new_draft.children_of(new_draft.types_de_champ_public.last).first
          new_draft.find_and_ensure_exclusive_use(child.stable_id).update(type_champ: :carte, options: { cadastres: true, znieff: true })
        end

        it do
          is_expected.to eq([
            {
              op: :update,
              attribute: :type_champ,
              label: "sub type de champ",
              private: false,
              from: "text",
              to: "carte",
              stable_id: new_draft.children_of(new_draft.types_de_champ_public.last).first.stable_id
            },
            {
              op: :update,
              attribute: :carte_layers,
              label: "sub type de champ",
              private: false,
              from: [],
              to: [:cadastres, :znieff],
              stable_id: new_draft.children_of(new_draft.types_de_champ_public.last).first.stable_id
            }
          ])
        end
      end

      describe '#compare_referentiel_changes' do
        let(:procedure) { create(:procedure, types_de_champ_public:) }
        let(:referentiel_1) do
          create(
            :referentiel,
            name: SecureRandom.uuid,
            url: 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/',
            mode: 'exact_match',
            test_data: 'PG46YY6YWCX8',
            hint: 'Saisissez le code de votre reference'
          )
        end
        let(:referentiel_2) do
          create(
            :referentiel,
            name: SecureRandom.uuid,
            url: 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/v2',
            mode: 'autocomplete',
            test_data: 'une autre',
            hint: 'Saisissez le code de votre autre reference'
          )
        end
        let(:types_de_champ_public) do
          [
            {
              type: :referentiel,
              referentiel: referentiel_1,
              referentiel_mapping: { key: 'value1' },
              stable_id: 123,
              libelle: 'libelle'
            }
          ]
        end

        before do
          updated_tdc = new_draft.find_and_ensure_exclusive_use(first_tdc.stable_id)
          updated_tdc.update(referentiel: referentiel_2, referentiel_mapping: { key: 'value2' })
        end

        it 'detects changes in referentiel url' do
          is_expected.to include({
            :attribute => :referentiel_url,
            :from => "https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/",
            :label => "libelle",
            :op => :update,
            :private => false,
            :stable_id => 123,
            :to => "https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/v2"
          })
          is_expected.to include({
            :attribute => :referentiel_mode,
            :from => "exact_match",
            :label => "libelle",
            :op => :update,
            :private => false,
            :stable_id => 123,
            :to => "autocomplete"
          })
          is_expected.to include({
            :attribute => :referentiel_hint,
            :from => 'Saisissez le code de votre reference',
            :label => "libelle",
            :op => :update,
            :private => false,
            :stable_id => 123,
            :to => 'Saisissez le code de votre autre reference'
          })
          is_expected.to include({
            :attribute => :referentiel_test_data,
            :from => 'PG46YY6YWCX8',
            :label => "libelle",
            :op => :update,
            :private => false,
            :stable_id => 123,
            :to => 'une autre'
          })
          is_expected.to include({
            :attribute => :referentiel_mapping,
            :from => { "key" => "value1" },
            :label => "libelle",
            :op => :update,
            :private => false,
            :stable_id => 123,
            :to => { "key" => "value2" }
          })
        end
      end
    end
  end

  describe 'compare_ineligibilite_rules' do
    include Logic
    let(:new_draft) { procedure.create_new_revision }
    subject { procedure.active_revision.compare_ineligibilite_rules(new_draft.reload) }

    context 'when ineligibilite_rules changes' do
      let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :yes_no }] }
      let(:yes_no_tdc) { new_draft.types_de_champ_public.first }

      context 'when nothing changed' do
        it { is_expected.to be_empty }
      end

      context 'when ineligibilite_rules added' do
        before do
          new_draft.update!(ineligibilite_rules: ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)))
        end

        it { is_expected.to include(an_instance_of(ProcedureRevisionChange::AddEligibiliteRuleChange)) }
      end

      context 'when ineligibilite_rules removed' do
        before do
          procedure.published_revision.update!(ineligibilite_rules: ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)))
        end

        it { is_expected.to include(an_instance_of(ProcedureRevisionChange::RemoveEligibiliteRuleChange)) }
      end

      context 'when ineligibilite_rules changed' do
        before do
          procedure.published_revision.update!(ineligibilite_rules: ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)))
          new_draft.update!(ineligibilite_rules: ds_and([
            ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)),
            empty_operator(empty, empty)
          ]))
        end

        it { is_expected.to include(an_instance_of(ProcedureRevisionChange::UpdateEligibiliteRuleChange)) }
      end

      context 'when when ineligibilite_enabled changes from false to true' do
        before do
          procedure.published_revision.update!(ineligibilite_enabled: false, ineligibilite_message: :required)
          new_draft.update!(ineligibilite_enabled: true, ineligibilite_message: :required)
        end

        it { is_expected.to include(an_instance_of(ProcedureRevisionChange::EligibiliteEnabledChange)) }
      end

      context 'when ineligibilite_enabled changes from true to false' do
        before do
          procedure.published_revision.update!(ineligibilite_enabled: true, ineligibilite_message: :required)
          new_draft.update!(ineligibilite_enabled: false, ineligibilite_message: :required)
        end

        it { is_expected.to include(an_instance_of(ProcedureRevisionChange::EligibiliteDisabledChange)) }
      end

      context 'when ineligibilite_message changes' do
        before do
          procedure.published_revision.update!(ineligibilite_message: :a)
          new_draft.update!(ineligibilite_message: :b)
        end

        it { is_expected.to include(an_instance_of(ProcedureRevisionChange::UpdateEligibiliteMessageChange)) }
      end
    end
  end

  describe 'ineligibilite_rules_are_valid?' do
    include Logic
    let(:procedure) { create(:procedure) }
    let(:draft_revision) { procedure.draft_revision }
    let(:ineligibilite_message) { 'ok' }
    let(:ineligibilite_enabled) { true }
    before do
      procedure.draft_revision.update(ineligibilite_rules:, ineligibilite_message:, ineligibilite_enabled:)
    end

    context 'when ineligibilite_rules are valid' do
      let(:ineligibilite_rules) { ds_eq(constant(true), constant(true)) }
      it 'is valid' do
        expect(draft_revision.validate(:publication)).to be_truthy
        expect(draft_revision.validate(:ineligibilite_rules_editor)).to be_truthy
      end
    end

    context 'when ineligibilite_rules are invalid on simple champ' do
      let(:ineligibilite_rules) { ds_eq(constant(true), constant(1)) }
      it 'is invalid when rule is incorrect' do
        expect(draft_revision.validate(:publication)).to be_falsey
        expect(draft_revision.validate(:ineligibilite_rules_editor)).to be_falsey
      end
    end

    context 'when ineligibilite_rules are invalid on simple champ' do
      let(:ineligibilite_rules) { empty_operator(empty, empty) }
      it 'is invalid when rule is empty' do
        expect(draft_revision.validate(:publication)).to be_falsey
        expect(draft_revision.validate(:ineligibilite_rules_editor)).to be_falsey
      end
    end

    context 'when ineligibilite_rules are invalid on repetition champ' do
      let(:ineligibilite_rules) { ds_eq(constant(true), constant(1)) }
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      let(:types_de_champ_public) { [{ type: :repetition, children: [{ type: :integer_number }] }] }
      let(:tdc_number) { draft_revision.types_de_champ_for(scope: :public).find { _1.type_champ == 'integer_number' } }
      let(:ineligibilite_rules) do
        ds_eq(champ_value(tdc_number.stable_id), constant(true))
      end
      it 'is invalid' do
        expect(draft_revision.validate(:publication)).to be_falsey
        expect(draft_revision.validate(:ineligibilite_rules_editor)).to be_falsey
      end
    end
  end

  describe 'children_of' do
    context 'with a simple tdc' do
      let(:procedure) { create(:procedure, :with_type_de_champ) }

      it { expect(draft.children_of(draft.types_de_champ.first)).to be_empty }
    end

    context 'with a repetition tdc' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :text }, { type: :integer_number }] }]) }
      let!(:parent) { draft.types_de_champ.find(&:repetition?) }
      let!(:first_child) { draft.types_de_champ.reject(&:repetition?).first }
      let!(:second_child) { draft.types_de_champ.reject(&:repetition?).second }

      it { expect(draft.children_of(parent)).to match([first_child, second_child]) }

      context 'with multiple child' do
        let(:child_position_2) { create(:type_de_champ_text) }
        let(:child_position_1) { create(:type_de_champ_text) }

        before do
          parent_coordinate = draft.revision_types_de_champ.find_by(type_de_champ_id: parent.id)
          draft.revision_types_de_champ.create(type_de_champ: child_position_2, position: 2, parent_id: parent_coordinate.id)
          draft.revision_types_de_champ.create(type_de_champ: child_position_1, position: 1, parent_id: parent_coordinate.id)
        end

        it 'returns the children in order' do
          expect(draft.children_of(parent)).to eq([first_child, second_child, child_position_1, child_position_2])
        end
      end

      context 'with multiple revision' do
        let(:new_child) { create(:type_de_champ_text) }
        let(:new_draft) do
          procedure.publish!
          procedure.draft_revision
        end

        before do
          new_draft
            .revision_types_de_champ
            .where(type_de_champ: first_child)
            .update(type_de_champ: new_child)
          new_draft.revision_types_de_champ.reload
        end

        it 'returns the children regarding the revision' do
          expect(draft.children_of(parent)).to match([first_child, second_child])
          expect(new_draft.children_of(parent)).to match([new_child, second_child])
        end
      end
    end
  end

  describe '#estimated_fill_duration' do
    let(:mandatory) { true }
    let(:description) { nil }
    let(:description_read_time) { ((description || "").split.size / TypesDeChamp::TypeDeChampBase::READ_WORDS_PER_SECOND).round }

    let(:types_de_champ_public) do
      [
        { mandatory: true, description: },
        { type: :siret, mandatory: true, description: },
        { type: :piece_justificative, mandatory:, description: }
      ]
    end
    let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ_public) }

    subject { procedure.active_revision.estimated_fill_duration }

    it 'sums the durations of public champs' do
      expect(subject).to eq \
          TypesDeChamp::TypeDeChampBase::FILL_DURATION_SHORT \
        + TypesDeChamp::TypeDeChampBase::FILL_DURATION_MEDIUM \
        + TypesDeChamp::TypeDeChampBase::FILL_DURATION_LONG \
        + 3 * description_read_time
    end

    context 'when some champs are optional' do
      let(:mandatory) { false }

      it 'estimates that half of optional champs will be filled' do
        expect(subject).to eq \
            TypesDeChamp::TypeDeChampBase::FILL_DURATION_SHORT \
          + TypesDeChamp::TypeDeChampBase::FILL_DURATION_MEDIUM \
          + 2 * description_read_time \
          + (description_read_time + TypesDeChamp::TypeDeChampBase::FILL_DURATION_LONG) / 2
      end
    end

    context 'when some champs have a description' do
      let(:description) { "some four words description" }

      it 'estimates that duration includes description reading time' do
        expect(subject).to eq \
            TypesDeChamp::TypeDeChampBase::FILL_DURATION_SHORT \
          + TypesDeChamp::TypeDeChampBase::FILL_DURATION_MEDIUM \
          + TypesDeChamp::TypeDeChampBase::FILL_DURATION_LONG \
          + 3 * description_read_time
      end
    end

    context 'when there are repetitions' do
      let(:types_de_champ_public) do
        [
          {
            type: :repetition,
            mandatory: true,
            description:,
            children: [
              { mandatory: true, description: "word " * 10 },
              { type: :piece_justificative, position: 2, mandatory: true, description: nil }
            ]
          }
        ]
      end

      it 'estimates that between 2 and 3 rows will be filled for each repetition' do
        repetable_block_read_duration = description_read_time

        row_duration = TypesDeChamp::TypeDeChampBase::FILL_DURATION_SHORT + TypesDeChamp::TypeDeChampBase::FILL_DURATION_LONG
        children_read_duration = (10 / TypesDeChamp::TypeDeChampBase::READ_WORDS_PER_SECOND).round

        expect(subject).to eq repetable_block_read_duration + row_duration * 2.5 + children_read_duration
      end
    end

    context 'when there are non fillable champs' do
      let(:types_de_champ_public) do
        [
          {
            type: :explication,
            description: "5 words description <strong>containing html</strong> " * 20
          },
          { mandatory: true, description: nil }
        ]
      end

      it 'estimates duration based on content reading' do
        expect(subject).to eq((100 / TypesDeChamp::TypeDeChampBase::READ_WORDS_PER_SECOND).round + TypesDeChamp::TypeDeChampBase::FILL_DURATION_SHORT)
      end
    end

    describe 'caching behavior', caching: true do
      let(:procedure) { create(:procedure, :published, types_de_champ_public: types_de_champ_public) }

      context 'when a type de champ belonging to a draft revision is updated' do
        let(:draft_revision) { procedure.draft_revision }

        before do
          draft_revision.estimated_fill_duration
          draft_revision.types_de_champ.first.update!(type_champ: TypeDeChamp.type_champs.fetch(:piece_justificative))
          draft_revision.reload
        end

        it 'returns an up-to-date estimate' do
          expect(draft_revision.estimated_fill_duration).to eq \
              TypesDeChamp::TypeDeChampBase::FILL_DURATION_LONG \
            + TypesDeChamp::TypeDeChampBase::FILL_DURATION_MEDIUM \
            + TypesDeChamp::TypeDeChampBase::FILL_DURATION_LONG \
            + 3 * description_read_time
        end
      end

      context 'when the revision is published (and thus immutable)' do
        let(:published_revision) { procedure.published_revision }

        it 'caches the estimate' do
          expect(published_revision).to receive(:compute_estimated_fill_duration).once
          published_revision.estimated_fill_duration
          published_revision.estimated_fill_duration
        end
      end
    end
  end

  describe 'conditions_are_valid' do
    include Logic

    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:types_de_champ_public) do
      [
        { type: :integer_number, libelle: 'l1' },
        { type: :integer_number, libelle: 'l2' }
      ]
    end
    def first_champ = procedure.draft_revision.types_de_champ_public.first
    def second_champ = procedure.draft_revision.types_de_champ_public.second

    let(:draft_revision) { procedure.draft_revision }
    let(:condition) { nil }

    subject do
      procedure.validate(:publication)
      procedure.errors
    end

    context 'when a champ has a valid condition (type)' do
      before { second_champ.update(condition: condition) }
      let(:condition) { ds_eq(constant(true), constant(true)) }

      it { is_expected.to be_empty }
    end

    context 'when a champ has a valid condition: needed tdc is up in the forms' do
      before { second_champ.update(condition: condition) }
      let(:condition) { ds_eq(champ_value(first_champ.stable_id), constant(1)) }

      it { is_expected.to be_empty }
    end

    context 'when a champ has an invalid condition' do
      before { second_champ.update(condition: condition) }
      let(:condition) { ds_eq(constant(true), constant(1)) }

      it { expect(subject.first.attribute).to eq(:draft_types_de_champ_public) }
    end

    context 'when a champ has an invalid condition: needed tdc is down in the forms' do
      let(:need_second_champ) { ds_eq(constant('oui'), champ_value(second_champ.stable_id)) }

      before do
        second_champ.update(condition: condition)
        first_champ.update(condition: need_second_champ)
      end

      it { expect(subject.first.attribute).to eq(:draft_types_de_champ_public) }
    end

    context 'with a repetition' do
      let(:procedure) do
        create(:procedure,
               types_de_champ_public: [{ type: :repetition, children: [{ type: :integer_number }, { type: :text }] }])
      end

      let(:children_of_repetition) do
        repetition = procedure.draft_revision.types_de_champ_public.find(&:repetition?)
        procedure.draft_revision.children_of(repetition)
      end

      let(:integer_champ) { children_of_repetition.first }
      let(:text_champ) { children_of_repetition.last }

      before { text_champ.update(condition: condition) }

      context 'when a child champ has a valid condition' do
        let(:condition) { ds_eq(champ_value(integer_champ.stable_id), constant(1)) }

        it { is_expected.to be_empty }
      end

      context 'when a champ belongs to a repetition' do
        let(:condition) { ds_eq(champ_value(-1), constant(1)) }

        it { expect(subject.first.attribute).to eq(:draft_types_de_champ_public) }
      end
    end
  end

  describe 'header_sections_are_valid' do
    let(:procedure) do
      create(:procedure).tap do |p|
        p.draft_revision.add_type_de_champ(type_champ: :header_section, libelle: 'hs', header_section_level: '2')
      end
    end
    let(:draft_revision) { procedure.draft_revision }

    subject do
      procedure.validate(:publication)
      procedure.errors
    end

    it 'find error' do
      expect(subject.errors).not_to be_empty
    end
  end

  describe "expressions_regulieres_are_valid" do
    let(:procedure) do
      create(:procedure).tap do |p|
        p.draft_revision.add_type_de_champ(type_champ: :formatted, libelle: 'exemple', formatted_mode: 'advanced', expression_reguliere:, expression_reguliere_exemple_text:)
      end
    end
    let(:draft_revision) { procedure.draft_revision }

    subject do
      procedure.validate(:publication)
      procedure.errors
    end

    context "When no regexp and no example" do
      let(:expression_reguliere_exemple_text) { nil }
      let(:expression_reguliere) { nil }

      it { is_expected.to be_empty }
    end

    context "When expression_reguliere but no example" do
      let(:expression_reguliere) { "[A-Z]+" }
      let(:expression_reguliere_exemple_text) { nil }

      it { is_expected.to be_empty }
    end

    context "When expression_reguliere and bad example" do
      let(:expression_reguliere_exemple_text) { "01234567" }
      let(:expression_reguliere) { "[A-Z]+" }

      it { is_expected.not_to be_empty }
    end

    context "When expression_reguliere and good example" do
      let(:expression_reguliere_exemple_text) { "A" }
      let(:expression_reguliere) { "[A-Z]+" }
      it { is_expected.to be_empty }
    end

    context "When bad expression_reguliere" do
      let(:expression_reguliere_exemple_text) { "0123456789" }
      let(:expression_reguliere) { "(" }

      it { is_expected.not_to be_empty }
    end

    context "When repetition" do
      let(:procedure) do
        create(:procedure,
          types_de_champ_public: [{ type: :repetition, children: [{ type: :formatted, formatted_mode: 'advanced', expression_reguliere:, expression_reguliere_exemple_text: }] }])
      end

      context "When bad expression_reguliere" do
        let(:expression_reguliere_exemple_text) { "0123456789" }
        let(:expression_reguliere) { "(" }

        it { is_expected.not_to be_empty }
      end

      context "When expression_reguliere and bad example" do
        let(:expression_reguliere_exemple_text) { "01234567" }
        let(:expression_reguliere) { "[A-Z]+" }

        it { is_expected.not_to be_empty }
      end
    end
  end

  describe "#dependent_conditions" do
    include Logic

    def first_champ = procedure.draft_revision.types_de_champ_public.first
    def second_champ = procedure.draft_revision.types_de_champ_public.second

    let(:procedure) do
      create(:procedure, types_de_champ_public: [{ type: :integer_number, libelle: 'l1' }]).tap do |p|
        tdc = p.draft_revision.revision_types_de_champ_public.last
        p.draft_revision.add_type_de_champ(type_champ: :integer_number,
                                           libelle: 'l2',
                                           condition: ds_eq(champ_value(tdc.stable_id), constant(true)),
                                           after_stable_id: tdc.stable_id)
      end
    end

    it { expect(draft.dependent_conditions(first_champ)).to eq([second_champ]) }
    it { expect(draft.dependent_conditions(second_champ)).to eq([]) }
  end

  describe 'only_present_on_draft?' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ libelle: 'Un champ texte' }]) }
    let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }

    it {
      expect(type_de_champ.only_present_on_draft?).to be_truthy
      procedure.publish!
      expect(type_de_champ.only_present_on_draft?).to be_falsey
      procedure.draft_revision.remove_type_de_champ(type_de_champ.stable_id)
      expect(type_de_champ.only_present_on_draft?).to be_falsey
      expect(type_de_champ.revisions.count).to eq(1)
      procedure.publish_revision!
      expect(type_de_champ.only_present_on_draft?).to be_falsey
      expect(type_de_champ.revisions.count).to eq(1)
    }
  end

  describe '#simple_routable_types_de_champ' do
    let(:procedure) do
      create(:procedure, types_de_champ_public: [
        { type: :text, libelle: 'l1' },
        { type: :drop_down_list, libelle: 'l2' },
        { type: :departements, libelle: 'l3' },
        { type: :regions, libelle: 'l4' },
        { type: :communes, libelle: 'l5' },
        { type: :epci, libelle: 'l6' }
      ])
    end

    it { expect(draft.simple_routable_types_de_champ.pluck(:libelle)).to eq(['l2', 'l3', 'l4', 'l5', 'l6']) }
  end
end
