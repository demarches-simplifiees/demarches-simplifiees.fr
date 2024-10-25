# frozen_string_literal: true

describe ExportTemplate do
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
  let(:export_template) { build(:export_template, kind: 'csv', groupe_instructeur:) }
  let(:tabular_export_template) { build(:tabular_export_template, groupe_instructeur:) }
  let(:procedure) { create(:procedure_with_dossiers, :published, types_de_champ_public:, for_individual:) }
  let(:for_individual) { true }
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: "Ca va ?", mandatory: true, stable_id: 1 },
      { type: :communes, libelle: "Commune", mandatory: true, stable_id: 17 },
      { type: :siret, libelle: 'siret', stable_id: 20 },
      { type: :repetition, mandatory: true, stable_id: 7, libelle: "Champ répétable", children: [{ type: 'text', libelle: 'Qqchose à rajouter?', stable_id: 8 }] }
    ]
  end

  describe '#exported_columns=' do
    it 'is assignable/readable with ExportedColumn object' do
      expect do
        export_template.exported_columns = [
          ExportedColumn.new(libelle: 'Ça va ?', column: procedure.find_column(label: "Ca va ?"))
        ]
        export_template.save!
        export_template.exported_columns
      end.not_to raise_error
    end
    it 'create exported_column' do
      export_template.exported_columns = [
        ExportedColumn.new(libelle: 'Ça va ?', column: procedure.find_column(label: "Ca va ?"))
      ]
      export_template.save!
      expect(export_template.exported_columns.size).to eq 1
    end

    context 'when there is a previous revision with a renamed tdc' do
      context 'with already column in export template' do
        let(:previous_tdc) { procedure.published_revision.types_de_champ_public.find_by(stable_id: 1) }
        let(:changed_tdc) { { libelle: "Ca roule ?" } }

        context 'with already column in export template' do
          before do
            export_template.exported_columns = [
              ExportedColumn.new(libelle: 'Ça va ?', column: procedure.find_column(label: "Ca va ?"))
            ]
            export_template.save!

            type_de_champ = procedure.draft_revision.find_and_ensure_exclusive_use(previous_tdc.stable_id)
            type_de_champ.update(changed_tdc)
            procedure.publish_revision!
          end

          it 'update columns with original libelle for champs with new revision' do
            Current.procedure_columns = {}
            procedure.reload
            export_template.reload
            expect(export_template.exported_columns.find { _1.column.stable_id.to_s == "1" }.libelle).to eq('Ça va ?')
          end
        end
      end
      context 'without columns in export template' do
        let(:previous_tdc) { procedure.published_revision.types_de_champ_public.find_by(stable_id: 1) }
        let(:changed_tdc) { { libelle: "Ca roule ?" } }

        before do
          type_de_champ = procedure.draft_revision.find_and_ensure_exclusive_use(previous_tdc.stable_id)
          type_de_champ.update(changed_tdc)
          procedure.publish_revision!

          export_template.exported_columns = [
            ExportedColumn.new(libelle: 'Ça roule ?', column: procedure.find_column(label: "Ca roule ?"))
          ]
          export_template.save!
        end

        it 'update columns with original libelle for champs with new revision' do
          Current.procedure_columns = {}
          procedure.reload
          export_template.reload
          expect(export_template.exported_columns.find { _1.column.stable_id.to_s == "1" }.libelle).to eq('Ça roule ?')
        end
      end
    end
  end
end
