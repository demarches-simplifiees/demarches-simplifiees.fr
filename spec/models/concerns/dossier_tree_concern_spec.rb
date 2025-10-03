# frozen_string_literal: true

describe DossierTreeConcern do
  describe '.link_parent_children!' do
    subject(:tree) { dossier.link_parent_children! }

    let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }
    let(:types_de_champ_public) { [] }
    let(:types_de_champ_private) { [] }

    context 'with a nested structure' do
      let(:types_de_champ_public) do
        [
          { type: :text, libelle: 'text' },
          { type: :header_section, level: 1, libelle: 'h1' },
          {
            type: :repetition,
            libelle: 'repetition',
            children: [
              { type: :header_section, level: 1, libelle: 'nested h1' },
              { type: :header_section, level: 2, libelle: 'nested h2' },
              { type: :text, libelle: 'nested text' },
              { type: :header_section, level: 1, libelle: 'another nested h1' }
            ]
          }
        ]
      end
      let(:header_section) { tree.second }
      let(:repetition) { header_section.children.first }
      let(:first_row) { repetition.new_rows.first }
      let(:nested_h1) { first_row.children.first }
      let(:nested_h2) { nested_h1.children.first }

      it do
        expect(tree.map(&:libelle)).to eq(["text", "h1"])
        expect(header_section.children.map(&:libelle)).to eq(["repetition"])
        expect(repetition.new_rows.first.children.map(&:libelle)).to eq(["nested h1", "another nested h1"])
        expect(nested_h2.libelle).to eq("nested h2")
        expect(nested_h2.children.map(&:libelle)).to eq(["nested text"])

        expect(nested_h2.parent).to eq(nested_h1)
        expect(nested_h1.parent).to eq(first_row)
        expect(first_row.parent).to eq(repetition)
        expect(repetition.parent).to eq(header_section)
        expect(header_section.parent).to be_nil
      end
    end

    context 'with private champs' do
      let(:types_de_champ_private) { [{ type: :text, libelle: 'private text' }] }

      it { expect(tree.filter(&:private).map(&:libelle)).to eq(['private text']) }
    end
  end

  describe '.submitted_tree' do
    subject(:submitted_tree) { dossier.submitted_tree }

    let!(:procedure) { create(:procedure, :published, types_de_champ_public:) }
    let!(:dossier) { create(:dossier, :en_construction, procedure:) }
    let(:types_de_champ_public) do
      [
        {
          type: :repetition,
          libelle: 'rep',
          children: [
            { type: :text, libelle: 'nested' },
            { type: :text, libelle: 'nested 2' }
          ]
        },
        { type: :text, libelle: 'text' }
      ]
    end
    let(:rep_tdc) { procedure.draft_revision.types_de_champ.find { it.libelle == 'rep' } }

    context 'when a repetition champ is removed' do
      before do
        procedure.draft_revision.remove_type_de_champ(rep_tdc.stable_id)

        procedure.publish_revision!
        perform_enqueued_jobs

        procedure.reload
        dossier.reload
      end
    end

    it do
      expect(submitted_tree.map(&:libelle)).to eq(["rep", "text"])
      expect(submitted_tree.first.new_rows.first.children.map(&:libelle)).to eq(["nested", "nested 2"])
    end
  end
end
