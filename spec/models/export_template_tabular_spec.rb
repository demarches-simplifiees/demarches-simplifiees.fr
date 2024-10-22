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

    xit 'raises when stable_id is invalid'
    xit 'raises when invalid path'

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
            expect(export_template.exported_columns.find { _1.column.column == "1" }.libelle).to eq('Ça va ?')
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
          expect(export_template.exported_columns.find { _1.column.column == "1" }.libelle).to eq('Ça roule ?')
        end
      end
    end
  end

  describe '#all_usager_columns' do
    context 'for individual procedure' do
      let(:for_individual) { true }

      it "returns all usager columns" do
        expected = [
          procedure.find_column(label: "Dossier ID"),
          procedure.find_column(label: "Demandeur"),
          procedure.find_column(label: "FranceConnect ?"),
          procedure.find_column(label: "Civilité"),
          procedure.find_column(label: "Nom"),
          procedure.find_column(label: "Prénom"),
          procedure.find_column(label: "Dépôt pour un tiers"),
          procedure.find_column(label: "Nom du mandataire"),
          procedure.find_column(label: "Prénom du mandataire")
        ]
        actuals = export_template.all_usager_columns.map(&:h_id)
        expected.each do |expected_col|
          expect(actuals).to include(expected_col.h_id)
        end
      end
    end

    context 'for entreprise procedure' do
      let(:for_individual) { false }

      it "returns all usager columns" do
        expected = [
          procedure.find_column(label: "Dossier ID"),
          procedure.find_column(label: "Demandeur"),
          procedure.find_column(label: "FranceConnect ?"),
          procedure.find_column(label: "SIRET"),
          procedure.find_column(label: "Établissement siège social"),
          procedure.find_column(label: "Établissement NAF"),
          procedure.find_column(label: "Libellé NAF"),
          procedure.find_column(label: "Établissement Adresse"),
          procedure.find_column(label: "Établissement numero voie"),
          procedure.find_column(label: "Établissement type voie"),
          procedure.find_column(label: "Établissement nom voie"),
          procedure.find_column(label: "Établissement complément adresse"),
          procedure.find_column(label: "Établissement code postal"),
          procedure.find_column(label: "Établissement localité"),
          procedure.find_column(label: "Établissement code INSEE localité"),
          procedure.find_column(label: "Entreprise SIREN"),
          procedure.find_column(label: "Entreprise capital social"),
          procedure.find_column(label: "Entreprise numero TVA intracommunautaire"),
          procedure.find_column(label: "Entreprise forme juridique"),
          procedure.find_column(label: "Entreprise forme juridique code"),
          procedure.find_column(label: "Entreprise nom commercial"),
          procedure.find_column(label: "Entreprise raison sociale"),
          procedure.find_column(label: "Entreprise SIRET siège social"),
          procedure.find_column(label: "Entreprise code effectif entreprise")
        ]
        actuals = export_template.all_usager_columns
        expected.each do |expected_col|
          expect(actuals.map(&:h_id)).to include(expected_col.h_id)
        end

        expect(actuals.any? { _1.label == "Nom" }).to eq false
      end
    end

    context 'when procedure chorusable' do
      let(:procedure) { create(:procedure_with_dossiers, :filled_chorus, types_de_champ_public:) }
      it 'returns specific chorus columns' do
        allow_any_instance_of(Procedure).to receive(:chorusable?).and_return(true)
        expected = [
          procedure.find_column(label: "Domaine fonctionnel"),
          procedure.find_column(label: "Référentiel de programmation"),
          procedure.find_column(label: "Centre de coût")
        ]
        actuals = export_template.all_usager_columns.map(&:h_id)
        expected.each do |expected_col|
          expect(actuals).to include(expected_col.h_id)
        end
      end
    end
  end

  describe '#all_dossier_columns' do
    it "returns all dossier columns" do
      expected = [
        procedure.find_column(label: "Archivé"),
        procedure.find_column(label: "Statut"),
        procedure.find_column(label: "Mis à jour le"),
        procedure.find_column(label: "Dernière mise à jour du dossier le"),
        procedure.find_column(label: "Déposé le"),
        procedure.find_column(label: "En instruction le"),
        procedure.find_column(label: "Terminé le"),
        procedure.find_column(label: "Motivation de la décision"),
        procedure.find_column(label: "Email instructeur"),
        procedure.find_column(label: "Groupe instructeur")
      ]
      actuals = export_template.all_dossier_columns.map(&:h_id)
      expected.each do |expected_col|
        expect(actuals).to include(expected_col.h_id)
      end
    end
  end

  describe 'dossier_exported_columns' do
    it 'fails' do
      expect(false).to be_truthy
    end
  end

  describe 'columns_for_stable_id' do
    it 'fails' do
      expect(false).to be_truthy
    end
  end
end
