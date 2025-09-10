# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DossierTree, type: :model do
  let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
  let(:types_de_champ_public) { [] }
  let(:types_de_champ_private) { [] }
  let(:procedure_coordinates) { procedure.active_revision.revision_types_de_champ.filter(&:public?) }
  let(:procedure_private_coordinates) { procedure.active_revision.revision_types_de_champ.filter(&:private?) }

  let(:text_0) { { libelle: 'Text (0)', stable_id: 99 } }
  let(:repetition_0) { { type: :repetition, libelle: 'Repetition (0)', children: repetition_0_children } }

  let(:header_1) { { type: :header_section, level: 1, libelle: 'Header 1' } }
  let(:text_1) { { libelle: 'Text (1)' } }
  let(:repetition_1) { { type: :repetition, libelle: 'Repetition (1)', children: repetition_1_children } }
  let(:checkbox_1) { { type: :checkbox, libelle: 'Checkbox (1)' } }
  let(:date_1) { { type: :date, libelle: 'Date (1)' } }
  let(:datetime_1) { { type: :datetime, libelle: 'DateTime (1)' } }

  let(:header_1_1) { { type: :header_section, level: 2, libelle: 'Header 1.1' } }
  let(:text_1_1) { { libelle: 'Text (1.1)' } }
  let(:repetition_1_1) { { type: :repetition, libelle: 'Repetition (1.1)', children: repetition_1_1_children } }
  let(:checkbox_1_1) { { type: :checkbox, libelle: 'Checkbox (1.1)' } }

  let(:header_1_1_1) { { type: :header_section, level: 3, libelle: 'Header 1.1.1' } }
  let(:text_1_1_1) { { libelle: 'Text (1.1.1)' } }
  let(:checkbox_1_1_1) { { type: :checkbox, libelle: 'Checkbox (1.1.1)' } }

  let(:header_1_1_2) { { type: :header_section, level: 3, libelle: 'Header 1.1.2' } }
  let(:text_1_1_2) { { libelle: 'Text (1.1.2)' } }
  let(:checkbox_1_1_2) { { type: :checkbox, libelle: 'Checkbox (1.1.2)' } }

  let(:header_1_2) { { type: :header_section, level: 2, libelle: 'Header 1.2' } }
  let(:text_1_2) { { libelle: 'Text (1.2)' } }
  let(:checkbox_1_2) { { type: :checkbox, libelle: 'Checkbox (1.2)' } }

  let(:header_1_2_1) { { type: :header_section, level: 3, libelle: 'Header 1.2.1' } }
  let(:text_1_2_1) { { libelle: 'Text (1.2.1)' } }
  let(:repetition_1_2_1) { { type: :repetition, libelle: 'Repetition (1.2.1)', children: repetition_1_2_1_children } }
  let(:checkbox_1_2_1) { { type: :checkbox, libelle: 'Checkbox (1.2.1)' } }

  let(:header_1_2_2) { { type: :header_section, level: 3, libelle: 'Header 1.2.2' } }
  let(:text_1_2_2) { { libelle: 'Text (1.2.2)' } }
  let(:repetition_1_2_2) { { type: :repetition, libelle: 'Repetition (1.2.2)', children: repetition_1_2_2_children } }
  let(:checkbox_1_2_2) { { type: :checkbox, libelle: 'Checkbox (1.2.2)' } }

  let(:header_2) { { type: :header_section, level: 1, libelle: 'Header 2' } }
  let(:text_2) { { libelle: 'Text (2)' } }

  let(:header_2_1) { { type: :header_section, level: 2, libelle: 'Header 2.1' } }
  let(:text_2_1) { { libelle: 'Text (2.1)' } }
  let(:repetition_2_1) { { type: :repetition, libelle: 'Repetition (2.1)', children: repetition_2_1_children } }

  let(:header_2_1_1) { { type: :header_section, level: 3, libelle: 'Header 2.1.1' } }
  let(:text_2_1_1) { { libelle: 'Text (2.1.1)' } }
  let(:repetition_2_1_1) { { type: :repetition, libelle: 'Repetition (2.1.1)', children: repetition_2_1_1_children } }

  let(:header_2_1_2) { { type: :header_section, level: 3, libelle: 'Header 2.1.2' } }
  let(:text_2_1_2) { { libelle: 'Text (2.1.2)' } }

  let(:header_2_2) { { type: :header_section, level: 2, libelle: 'Header 2.2' } }
  let(:text_2_2) { { libelle: 'Text (2.2)' } }

  let(:header_2_2_1) { { type: :header_section, level: 3, libelle: 'Header 2.2.1' } }
  let(:text_2_2_1) { { libelle: 'Text (2.2.1)' } }

  let(:header_2_2_2) { { type: :header_section, level: 3, libelle: 'Header 2.2.2' } }
  let(:text_2_2_2) { { libelle: 'Text (2.2.2)' } }
  let(:repetition_2_2_2) { { type: :repetition, libelle: 'Repetition (2.2.2)', children: repetition_2_2_2_children } }

  let(:repetition_1_header_1) { { type: :header_section, level: 1, libelle: 'Repetition (1) - Header 1' } }
  let(:repetition_1_header_1_1) { { type: :header_section, level: 2, libelle: 'Repetition (1) - Header 1.1' } }
  let(:repetition_1_header_1_1_1) { { type: :header_section, level: 3, libelle: 'Repetition (1) - Header 1.1.1' } }

  let(:repetition_0_children) { [{ libelle: 'Repetition (0) - Text (0)' }] }
  let(:repetition_1_children) do
    [
      { libelle: 'Repetition (1) - Text (0)' },
      repetition_1_header_1,
      { libelle: 'Repetition (1) - Text (1)' },
      repetition_1_header_1_1,
      { libelle: 'Repetition (1) - Text (1.1)' },
      repetition_1_header_1_1_1,
      { libelle: 'Repetition (1) - Text (1.1.1)' }
    ]
  end
  let(:repetition_1_1_children) { [{ libelle: 'Repetition (1.1) - Text (0)' }] }
  let(:repetition_1_2_1_children) { [{ libelle: 'Repetition (1.2.1) - Text (0)' }] }
  let(:repetition_1_2_2_children) { [{ libelle: 'Repetition (1.2.2) - Text (0)' }] }
  let(:repetition_2_1_children) { [{ libelle: 'Repetition (2.1) - Text (0)' }] }
  let(:repetition_2_1_1_children) { [{ libelle: 'Repetition (2.1.1) - Text (0)' }] }
  let(:repetition_2_2_2_children) { [{ libelle: 'Repetition (2.2.2) - Text (0)' }] }

  describe 'tree' do
    let(:tree) { DossierTree::Builder.procedure_tree(procedure_coordinates, procedure:) }

    it 'empty' do
      expect(tree.children.size).to eq(0)
    end

    context 'with all champs and sections' do
      let(:types_de_champ_public) do
        [
          text_0,
          repetition_0,

          header_1,
          text_1,
          repetition_1,
          checkbox_1,
          date_1,
          datetime_1,

          header_1_1,
          text_1_1,
          repetition_1_1,
          checkbox_1_1,

          header_1_1_1,
          text_1_1_1,
          checkbox_1_1_1,

          header_1_1_2,
          text_1_1_2,
          checkbox_1_1_2,

          header_1_2,
          text_1_2,
          checkbox_1_2,

          header_1_2_1,
          text_1_2_1,
          repetition_1_2_1,
          checkbox_1_2_1,

          header_1_2_2,
          text_1_2_2,
          repetition_1_2_2,
          checkbox_1_2_2,

          header_2,
          text_2,

          header_2_1,
          text_2_1,
          repetition_2_1,

          header_2_1_1,
          text_2_1_1,
          repetition_2_1_1,

          header_2_1_2,
          text_2_1_2,

          header_2_2,
          text_2_2,

          header_2_2_1,
          text_2_2_1,

          header_2_2_2,
          text_2_2_2,
          repetition_2_2_2
        ]
      end

      let(:header_1_node) { tree.children.third }
      let(:header_1_1_node) { header_1_node.children[-2] }
      let(:header_1_1_1_node) { header_1_1_node.children.fourth }
      let(:header_1_1_2_node) { header_1_1_node.children.fifth }
      let(:header_1_2_node) { header_1_node.children[-1] }

      let(:header_2_node) { tree.children.fourth }
      let(:header_2_2_node) { header_2_node.children.third }
      let(:header_2_2_2_node) { header_2_2_node.children.third }

      let(:repetition_0_node) { tree.children.second }
      let(:repetition_0_first_row) { repetition_0_node.rows.first }
      let(:repetition_1_node) { header_1_node.children.second }
      let(:repetition_1_first_row) { repetition_1_node.rows.first }

      let(:repetition_1_header_1_node) { repetition_1_first_row.children.second }
      let(:repetition_1_header_1_1_node) { repetition_1_header_1_node.children.second }
      let(:repetition_1_header_1_1_1_node) { repetition_1_header_1_1_node.children.second }

      it 'should build tree' do
        expect(tree.children.size).to eq 4
        expect(tree.children.map(&:depth)).to eq [0, 0, 0, 0]
        expect(tree.children.filter(&:section?).map(&:level)).to eq [1, 1]
        expect(tree.children.map(&:libelle)).to eq ['Text (0)', 'Repetition (0)', 'Header 1', 'Header 2']
        expect(tree.children.map(&:champ?)).to eq [true, false, false, false]
        expect(tree.children.map(&:section?)).to eq [false, false, true, true]
        expect(tree.children.map(&:repeater?)).to eq [false, true, false, false]
        expect(tree.children.map(&:visible?)).to eq [true, true, true, true]
        expect(tree.children.filter(&:champ?).map { _1.value.blank? }).to eq [true]

        expect(repetition_0_node.rows.size).to eq 1
        expect(repetition_0_node.libelle).to eq 'Repetition (0)'
        expect(repetition_0_first_row.children.size).to eq 1
        expect(repetition_0_first_row.children.map(&:libelle)).to eq ['Repetition (0) - Text (0)']
        expect(repetition_0_first_row.children.map(&:depth)).to eq [1]

        expect(header_1_node.children.size).to eq 7
        expect(header_1_node.libelle).to eq 'Header 1'
        expect(header_1_node.children.map(&:depth)).to eq [1, 1, 1, 1, 1, 1, 1]
        expect(header_1_node.children.filter(&:section?).map(&:level)).to eq [2, 2]
        expect(header_1_node.children.map(&:libelle)).to eq ['Text (1)', 'Repetition (1)', 'Checkbox (1)', 'Date (1)', 'DateTime (1)', 'Header 1.1', 'Header 1.2']
        expect(header_1_node.children.map(&:champ?)).to eq [true, false, true, true, true, false, false]
        expect(header_1_node.children.map(&:section?)).to eq [false, false, false, false, false, true, true]
        expect(header_1_node.children.map(&:repeater?)).to eq [false, true, false, false, false, false, false]
        expect(header_1_node.children.map(&:visible?)).to eq [true, true, true, true, true, true, true]

        expect(repetition_1_node.rows.size).to eq 1
        expect(repetition_1_node.libelle).to eq 'Repetition (1)'
        expect(repetition_1_node.depth).to eq 1
        expect(repetition_1_first_row.children.size).to eq 2
        expect(repetition_1_first_row.children.map(&:libelle)).to eq ['Repetition (1) - Text (0)', 'Repetition (1) - Header 1']
        expect(repetition_1_first_row.children.map(&:depth)).to eq [2, 2]
        expect(repetition_1_first_row.children.filter(&:section?).map(&:level)).to eq [1]

        expect(repetition_1_header_1_node.children.size).to eq 2
        expect(repetition_1_header_1_node.children.map(&:libelle)).to eq ['Repetition (1) - Text (1)', 'Repetition (1) - Header 1.1']
        expect(repetition_1_header_1_node.children.map(&:depth)).to eq [3, 3]
        expect(repetition_1_header_1_node.children.filter(&:section?).map(&:level)).to eq [2]

        expect(repetition_1_header_1_1_node.children.size).to eq 2
        expect(repetition_1_header_1_1_node.children.map(&:libelle)).to eq ['Repetition (1) - Text (1.1)', 'Repetition (1) - Header 1.1.1']
        expect(repetition_1_header_1_1_node.children.map(&:depth)).to eq [4, 4]
        expect(repetition_1_header_1_1_node.children.filter(&:section?).map(&:level)).to eq [3]

        expect(repetition_1_header_1_1_1_node.children.size).to eq 1
        expect(repetition_1_header_1_1_1_node.children.map(&:libelle)).to eq ['Repetition (1) - Text (1.1.1)']
        expect(repetition_1_header_1_1_1_node.children.map(&:depth)).to eq [5]

        expect(header_1_1_node.children.size).to eq 5
        expect(header_1_1_node.libelle).to eq 'Header 1.1'
        expect(header_1_1_node.children.map(&:depth)).to eq [2, 2, 2, 2, 2]
        expect(header_1_1_node.children.map(&:libelle)).to eq ['Text (1.1)', 'Repetition (1.1)', 'Checkbox (1.1)', 'Header 1.1.1', 'Header 1.1.2']
        expect(header_1_1_node.children.map(&:champ?)).to eq [true, false, true, false, false]
        expect(header_1_1_node.children.map(&:section?)).to eq [false, false, false, true, true]
        expect(header_1_1_node.children.map(&:repeater?)).to eq [false, true, false, false, false]

        expect(header_1_1_1_node.children.size).to eq 2
        expect(header_1_1_1_node.libelle).to eq 'Header 1.1.1'
        expect(header_1_1_1_node.depth).to eq 2
        expect(header_1_1_1_node.level).to eq 3
        expect(header_1_1_1_node.children.map(&:depth)).to eq [3, 3]
        expect(header_1_1_1_node.children.map(&:libelle)).to eq ['Text (1.1.1)', 'Checkbox (1.1.1)']
        expect(header_1_1_1_node.children.map(&:champ?)).to eq [true, true]

        expect(header_1_1_2_node.children.size).to eq 2
        expect(header_1_1_2_node.libelle).to eq 'Header 1.1.2'
        expect(header_1_1_2_node.depth).to eq 2
        expect(header_1_1_2_node.level).to eq 3
        expect(header_1_1_2_node.children.map(&:depth)).to eq [3, 3]
        expect(header_1_1_2_node.children.map(&:libelle)).to eq ['Text (1.1.2)', 'Checkbox (1.1.2)']
        expect(header_1_1_2_node.children.map(&:champ?)).to eq [true, true]

        expect(header_1_2_node.children.size).to eq 4
        expect(header_1_2_node.libelle).to eq 'Header 1.2'
        expect(header_1_2_node.depth).to eq 1
        expect(header_1_2_node.level).to eq 2
        expect(header_1_2_node.children.map(&:depth)).to eq [2, 2, 2, 2]
        expect(header_1_2_node.children.map(&:libelle)).to eq ['Text (1.2)', 'Checkbox (1.2)', 'Header 1.2.1', 'Header 1.2.2']
        expect(header_1_2_node.children.map(&:champ?)).to eq [true, true, false, false]
        expect(header_1_2_node.children.map(&:section?)).to eq [false, false, true, true]
        expect(header_1_2_node.children.map(&:repeater?)).to eq [false, false, false, false]

        expect(header_2_node.children.size).to eq 3
        expect(header_2_node.libelle).to eq 'Header 2'
        expect(header_2_node.depth).to eq 0
        expect(header_2_node.level).to eq 1
        expect(header_2_node.children.map(&:depth)).to eq [1, 1, 1]
        expect(header_2_node.children.filter(&:section?).map(&:level)).to eq [2, 2]
        expect(header_2_node.children.map(&:libelle)).to eq ['Text (2)', 'Header 2.1', 'Header 2.2']
        expect(header_2_node.children.map(&:champ?)).to eq [true, false, false]
        expect(header_2_node.children.map(&:section?)).to eq [false, true, true]
        expect(header_2_node.children.map(&:repeater?)).to eq [false, false, false]

        expect(header_2_2_2_node.children.size).to eq 2
        expect(header_2_2_2_node.libelle).to eq 'Header 2.2.2'
        expect(header_2_2_2_node.depth).to eq 2
        expect(header_2_2_2_node.level).to eq 3
        expect(header_2_2_2_node.children.map(&:depth)).to eq [3, 3]
        expect(header_2_2_2_node.children.map(&:libelle)).to eq ['Text (2.2.2)', 'Repetition (2.2.2)']
        expect(header_2_2_2_node.children.map(&:champ?)).to eq [true, false]
        expect(header_2_2_2_node.children.map(&:section?)).to eq [false, false]
        expect(header_2_2_2_node.children.map(&:repeater?)).to eq [false, true]

        expect(tree.champs.size).to eq 35
        expect(tree.sections.size).to eq 17
        expect(tree.repeaters.size).to eq 8

        expect(ActionView::RecordIdentifier.dom_id(tree.children.first)).to eq 'champ_99'
      end

      context 'with dossier' do
        let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
        let(:tree) { DossierTree::Builder.dossier_trees(procedure_coordinates, [], dossier:).first }

        it 'should build tree' do
          expect(tree.children.size).to eq 4
          expect(tree.children.map(&:depth)).to eq [0, 0, 0, 0]
          expect(tree.children.filter(&:section?).map(&:level)).to eq [1, 1]
          expect(tree.children.map(&:libelle)).to eq ['Text (0)', 'Repetition (0)', 'Header 1', 'Header 2']
          expect(tree.children.map(&:champ?)).to eq [true, false, false, false]
          expect(tree.children.map(&:section?)).to eq [false, false, true, true]
          expect(tree.children.map(&:repeater?)).to eq [false, true, false, false]
          expect(tree.children.map(&:visible?)).to eq [true, true, true, true]
          expect(tree.children.filter(&:champ?).map { _1.value.blank? }).to eq [false]
          expect(tree.children.first.value).to eq 'text'

          expect(repetition_0_node.rows.size).to eq 2
          expect(repetition_0_node.libelle).to eq 'Repetition (0)'
          expect(repetition_0_first_row.children.size).to eq 1
          expect(repetition_0_first_row.children.map(&:libelle)).to eq ['Repetition (0) - Text (0)']
          expect(repetition_0_first_row.children.map(&:depth)).to eq [1]

          expect(header_1_node.children.size).to eq 7
          expect(header_1_node.libelle).to eq 'Header 1'
          expect(header_1_node.children.map(&:depth)).to eq [1, 1, 1, 1, 1, 1, 1]
          expect(header_1_node.children.filter(&:section?).map(&:level)).to eq [2, 2]
          expect(header_1_node.children.map(&:libelle)).to eq ['Text (1)', 'Repetition (1)', 'Checkbox (1)', 'Date (1)', 'DateTime (1)', 'Header 1.1', 'Header 1.2']
          expect(header_1_node.children.map(&:champ?)).to eq [true, false, true, true, true, false, false]
          expect(header_1_node.children.map(&:section?)).to eq [false, false, false, false, false, true, true]
          expect(header_1_node.children.map(&:repeater?)).to eq [false, true, false, false, false, false, false]
          expect(header_1_node.children.filter(&:champ?).map(&:value)).to eq ['text', true, Date.parse('2019-07-10'), Time.zone.parse('15/09/1962 15:35')]
          expect(header_1_node.children.map(&:visible?)).to eq [true, true, true, true, true, true, true]

          expect(repetition_1_node.rows.size).to eq 2
          expect(repetition_1_node.libelle).to eq 'Repetition (1)'
          expect(repetition_1_node.depth).to eq 1
          expect(repetition_1_first_row.children.size).to eq 2
          expect(repetition_1_first_row.children.map(&:libelle)).to eq ['Repetition (1) - Text (0)', 'Repetition (1) - Header 1']
          expect(repetition_1_first_row.children.map(&:depth)).to eq [2, 2]
          expect(repetition_1_first_row.children.filter(&:section?).map(&:level)).to eq [1]

          expect(repetition_1_header_1_node.children.size).to eq 2
          expect(repetition_1_header_1_node.children.map(&:libelle)).to eq ['Repetition (1) - Text (1)', 'Repetition (1) - Header 1.1']
          expect(repetition_1_header_1_node.children.map(&:depth)).to eq [3, 3]
          expect(repetition_1_header_1_node.children.filter(&:section?).map(&:level)).to eq [2]

          expect(repetition_1_header_1_1_node.children.size).to eq 2
          expect(repetition_1_header_1_1_node.children.map(&:libelle)).to eq ['Repetition (1) - Text (1.1)', 'Repetition (1) - Header 1.1.1']
          expect(repetition_1_header_1_1_node.children.map(&:depth)).to eq [4, 4]
          expect(repetition_1_header_1_1_node.children.filter(&:section?).map(&:level)).to eq [3]

          expect(repetition_1_header_1_1_1_node.children.size).to eq 1
          expect(repetition_1_header_1_1_1_node.children.map(&:libelle)).to eq ['Repetition (1) - Text (1.1.1)']
          expect(repetition_1_header_1_1_1_node.children.map(&:depth)).to eq [5]

          expect(header_1_1_node.children.size).to eq 5
          expect(header_1_1_node.libelle).to eq 'Header 1.1'
          expect(header_1_1_node.children.map(&:depth)).to eq [2, 2, 2, 2, 2]
          expect(header_1_1_node.children.map(&:libelle)).to eq ['Text (1.1)', 'Repetition (1.1)', 'Checkbox (1.1)', 'Header 1.1.1', 'Header 1.1.2']
          expect(header_1_1_node.children.map(&:champ?)).to eq [true, false, true, false, false]
          expect(header_1_1_node.children.map(&:section?)).to eq [false, false, false, true, true]
          expect(header_1_1_node.children.map(&:repeater?)).to eq [false, true, false, false, false]

          expect(header_1_1_1_node.children.size).to eq 2
          expect(header_1_1_1_node.libelle).to eq 'Header 1.1.1'
          expect(header_1_1_1_node.depth).to eq 2
          expect(header_1_1_1_node.level).to eq 3
          expect(header_1_1_1_node.children.map(&:depth)).to eq [3, 3]
          expect(header_1_1_1_node.children.map(&:libelle)).to eq ['Text (1.1.1)', 'Checkbox (1.1.1)']
          expect(header_1_1_1_node.children.map(&:champ?)).to eq [true, true]

          expect(header_1_1_2_node.children.size).to eq 2
          expect(header_1_1_2_node.libelle).to eq 'Header 1.1.2'
          expect(header_1_1_2_node.depth).to eq 2
          expect(header_1_1_2_node.level).to eq 3
          expect(header_1_1_2_node.children.map(&:depth)).to eq [3, 3]
          expect(header_1_1_2_node.children.map(&:libelle)).to eq ['Text (1.1.2)', 'Checkbox (1.1.2)']
          expect(header_1_1_2_node.children.map(&:champ?)).to eq [true, true]

          expect(header_1_2_node.children.size).to eq 4
          expect(header_1_2_node.libelle).to eq 'Header 1.2'
          expect(header_1_2_node.depth).to eq 1
          expect(header_1_2_node.level).to eq 2
          expect(header_1_2_node.children.map(&:depth)).to eq [2, 2, 2, 2]
          expect(header_1_2_node.children.map(&:libelle)).to eq ['Text (1.2)', 'Checkbox (1.2)', 'Header 1.2.1', 'Header 1.2.2']
          expect(header_1_2_node.children.map(&:champ?)).to eq [true, true, false, false]
          expect(header_1_2_node.children.map(&:section?)).to eq [false, false, true, true]
          expect(header_1_2_node.children.map(&:repeater?)).to eq [false, false, false, false]

          expect(header_2_node.children.size).to eq 3
          expect(header_2_node.libelle).to eq 'Header 2'
          expect(header_2_node.depth).to eq 0
          expect(header_2_node.level).to eq 1
          expect(header_2_node.children.map(&:depth)).to eq [1, 1, 1]
          expect(header_2_node.children.filter(&:section?).map(&:level)).to eq [2, 2]
          expect(header_2_node.children.map(&:libelle)).to eq ['Text (2)', 'Header 2.1', 'Header 2.2']
          expect(header_2_node.children.map(&:champ?)).to eq [true, false, false]
          expect(header_2_node.children.map(&:section?)).to eq [false, true, true]
          expect(header_2_node.children.map(&:repeater?)).to eq [false, false, false]

          expect(header_2_2_2_node.children.size).to eq 2
          expect(header_2_2_2_node.libelle).to eq 'Header 2.2.2'
          expect(header_2_2_2_node.depth).to eq 2
          expect(header_2_2_2_node.level).to eq 3
          expect(header_2_2_2_node.children.map(&:depth)).to eq [3, 3]
          expect(header_2_2_2_node.children.map(&:libelle)).to eq ['Text (2.2.2)', 'Repetition (2.2.2)']
          expect(header_2_2_2_node.children.map(&:champ?)).to eq [true, false]
          expect(header_2_2_2_node.children.map(&:section?)).to eq [false, false]
          expect(header_2_2_2_node.children.map(&:repeater?)).to eq [false, true]

          expect(tree.champs.size).to eq 46
          expect(tree.sections.size).to eq 20
          expect(tree.repeaters.size).to eq 8

          expect(ActionView::RecordIdentifier.dom_id(tree.children.first)).to eq 'champ_99'
        end
      end
    end
  end

  describe 'visibility' do
    include Logic

    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:trees) { DossierTree::Builder.dossier_trees(procedure_coordinates, procedure_private_coordinates, dossier:) }
    let(:tree) { trees.first }
    let(:derived_tree) { trees.second }

    let(:checkbox_0) { { type: :checkbox, libelle: 'Checkbox (0)', stable_id: 99 } }
    let(:yes_no_0) { { type: :checkbox, libelle: 'YesNo (0)', stable_id: 199, condition: ds_eq(champ_value(99), constant(true)) } }
    let(:text_0) { { libelle: 'Text (0)', condition: ds_eq(champ_value(99), constant(true)) } }
    let(:header_1) { { type: :header_section, libelle: 'Header 1', condition: ds_eq(champ_value(199), constant(true)) } }
    let(:checkbox_1) { { type: :checkbox, libelle: 'Checkbox (1)', stable_id: 299 } }
    let(:text_1) { { libelle: 'Text (1)', condition: ds_eq(champ_value(299), constant(true)) } }
    let(:repetition_1) { { type: :repetition, libelle: 'Repetition (1)', children: repetition_1_children, condition: ds_eq(champ_value(299), constant(true)) } }

    let(:repetition_1_header_1) { { type: :header_section, level: 1, libelle: 'Repetition (1) - Header 1', condition: ds_eq(champ_value(399), constant(true)) } }
    let(:repetition_1_children) do
      [
        { type: :checkbox, libelle: 'Repetition (1) - Checkbox (0)', stable_id: 399 },
        { libelle: 'Repetition (1) - Text (0)', condition: ds_eq(champ_value(399), constant(true)) },
        repetition_1_header_1,
        { libelle: 'Repetition (1) - Text (1)' }
      ]
    end

    let(:types_de_champ_public) do
      [
        checkbox_0,
        yes_no_0,
        text_0,
        header_1,
        checkbox_1,
        text_1,
        repetition_1
      ]
    end

    context.skip 'not visible' do
      before {
        dossier.champs.find { _1.stable_id == 99 }.update(value: 'false')
      }

      it 'should not be visible' do
        expect(tree.children.map(&:visible?)).to eq [true, false, false, false]
        expect(tree.children.fourth.children.map(&:visible?)).to eq [false, false, false]
      end
    end

    context 'visible' do
      it 'should be visible' do
        expect(tree.children.map(&:visible?)).to eq [true, true, true, true]
        expect(tree.children.fourth.children.map(&:visible?)).to eq [true, true, true]
      end
    end

    context.skip 'ancestor not visible' do
      before {
        dossier.champs.find { _1.stable_id == 199 }.update(value: 'false')
      }

      it 'with hidden ancestor should not be visible' do
        expect(tree.children.map(&:visible?)).to eq [true, true, true, false]
        expect(tree.children.fourth.children.map(&:visible?)).to eq [false, false, false]
        expect(tree.children.fourth.children.third.rows.map(&:visible?)).to eq [false, false]
        expect(tree.children.fourth.children.third.rows.first.children.map(&:visible?)).to eq [false, false, false]
        expect(tree.children.fourth.children.third.rows.second.children.map(&:visible?)).to eq [false, false, false]
      end
    end

    context 'nested not visible' do
      before {
        dossier.champs.find { _1.stable_id == 299 }.update(value: 'false')
      }

      it 'should not be visible' do
        expect(tree.children.map(&:visible?)).to eq [true, true, true, true]
        expect(tree.children.fourth.children.map(&:visible?)).to eq [true, false, false]
        expect(tree.children.fourth.children.third.rows.map(&:visible?)).to eq [false, false]
        expect(tree.children.fourth.children.third.rows.first.children.map(&:visible?)).to eq [false, false, false]
        expect(tree.children.fourth.children.third.rows.second.children.map(&:visible?)).to eq [false, false, false]
      end
    end

    context.skip 'in row not visible' do
      before {
        dossier.champs.find { _1.stable_id == 399 }.update(value: 'false')
      }

      it 'should not be visible' do
        expect(tree.children.map(&:visible?)).to eq [true, true, true, true]
        expect(tree.children.fourth.children.map(&:visible?)).to eq [true, true, true]
        expect(tree.children.fourth.children.third.rows.map(&:visible?)).to eq [true, true]
        expect(tree.children.fourth.children.third.rows.first.children.map(&:visible?)).to eq [true, false, false]
        expect(tree.children.fourth.children.third.rows.second.children.map(&:visible?)).to eq [true, true, true]
        expect(tree.children.fourth.children.third.rows.first.children.last.children.map(&:visible?)).to eq [false]
        expect(tree.children.fourth.children.third.rows.second.children.last.children.map(&:visible?)).to eq [true]
      end
    end

    context 'private depending on public' do
      let(:private_text_0) { { libelle: 'Private Text (0)', condition: ds_eq(champ_value(99), constant(true)) } }
      let(:private_textarea_0) { { libelle: 'Private Textarea (0)', condition: ds_eq(champ_value(199), constant(true)) } }

      let(:types_de_champ_private) do
        [private_text_0, private_textarea_0]
      end

      context 'not visible' do
        before {
          dossier.champs.find { _1.stable_id == 99 }.update(value: 'false')
        }

        it 'should not be visible' do
          expect(derived_tree.children.map(&:visible?)).to eq [false, false]
        end
      end

      context.skip 'ancestor not visible' do
        before {
          dossier.champs.find { _1.stable_id == 199 }.update(value: 'false')
        }

        it 'with hidden ancestor should not be visible' do
          expect(derived_tree.children.map(&:visible?)).to eq [true, false]
        end
      end

      context 'visible' do
        it 'should be visible' do
          expect(derived_tree.children.map(&:visible?)).to eq [true, true]
        end
      end
    end
  end

  describe 'sections' do
    let(:tree) { DossierTree::Builder.procedure_tree(procedure_coordinates, procedure:) }

    context 'with invalid sections order' do
      let(:types_de_champ_public) do
        [
          { libelle: 'Text 0' },
          { type: :header_section, level: 3, libelle: 'Header 1.1.1' },
          { libelle: 'Text 1.1.1' },
          { type: :header_section, level: 2, libelle: 'Header 1.1' },
          { libelle: 'Text 1.1' },
          { type: :header_section, level: 1, libelle: 'Header 1' },
          { libelle: 'Text 1' }
        ]
      end

      it 'should build tree' do
        expect(tree.children.size).to eq 3
        expect(tree.children.map(&:libelle)).to eq ["Text 0", "Header 1.1.1", "Header 1"]
        expect(tree.children.second.children.map(&:libelle)).to eq ["Text 1.1.1", "Header 1.1"]
        expect(tree.children.third.children.map(&:libelle)).to eq ["Text 1"]
        expect(tree.children.second.children.second.children.map(&:libelle)).to eq ["Text 1.1"]
      end
    end
  end
end
