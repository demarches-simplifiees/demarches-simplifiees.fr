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

  describe '#columns=' do
    let(:columns) {
  [
    { :path => "id", :source => "dossier" },
    { :path => "email", :source => "dossier" },
    { :path => "archived", :source => "dossier" },
    { :path => "dossier_state", :source => "dossier" },
    { :path => "value", :source => "tdc", :stable_id => 1 },
    { :path => "value", :source => "tdc", :stable_id => 17 },
    { :path => "code", :source => "tdc", :stable_id => 17 },
    { :path => "value", :repetition_champ_stable_id => 7, :source => "repet", :stable_id => 8 }
  ]
}

    it 'update columns when assiging columns' do
      export_template.columns = columns
      expect(export_template.columns).to match_array [
        { :libelle => "ID", :path => "id", :source => "dossier" },
        { :libelle => "Email", :path => "email", :source => "dossier" },
        { :libelle => "Archivé", :path => "archived", :source => "dossier" },
        { :libelle => "État du dossier", :path => "dossier_state", :source => "dossier" },
        { :libelle => "Ca va ?", :path => "value", :source => "tdc", :stable_id => 1 },
        { :libelle => "Commune", :path => "value", :source => "tdc", :stable_id => 17 },
        { :libelle => "Commune (Code INSEE)", :path => "code", :source => "tdc", :stable_id => 17 },
        { :libelle => "Qqchose à rajouter?", :path => "value", :repetition_champ_stable_id => 7, :source => "repet", :stable_id => 8 }
      ]
    end

    context 'when there is a previous revision with a renamed tdc' do
      let(:previous_tdc) { procedure.published_revision.types_de_champ_public.find_by(stable_id: 1) }
      let(:changed_tdc) { { libelle: "Ca roule ?" } }

      context 'with already column in export template' do
        before do
          export_template.columns = columns
          type_de_champ = procedure.draft_revision.find_and_ensure_exclusive_use(previous_tdc.stable_id)
          type_de_champ.update(changed_tdc)
          procedure.publish_revision!
          export_template.columns = columns
        end

        it 'update columns with original libelle for champs with new revision' do
          expect(export_template.columns.find { _1[:stable_id] == 1 }).to eq({ :libelle => "Ca va ?", :path => "value", :source => "tdc", :stable_id => 1 })
        end
      end

      context 'without columns in export template' do
        before do
          type_de_champ = procedure.draft_revision.find_and_ensure_exclusive_use(previous_tdc.stable_id)
          type_de_champ.update(changed_tdc)
          procedure.publish_revision!
          export_template.columns = columns
        end

        it 'update columns with new libelle for champs with new revision' do
          expect(export_template.columns.find { _1[:stable_id] == 1 }).to eq({ :libelle => "Ca roule ?", :path => "value", :source => "tdc", :stable_id => 1 })
        end
      end
    end
    it 'ignores columns when invalid stable_id' do
      export_template.columns = [{ :path => "value", :source => "tdc", :stable_id => 987 }]
      expect(export_template.columns).to match_array []
    end

    it 'raises when invalid path' do
      expect { export_template.columns = ['blabla'] }.to raise_exception
    end
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

  describe '#all_tdc_columns' do
    xit "returns all tdc columns (without repetition) based upon procedure's type de champs" do
      expect(export_template.all_tdc_columns).to match_array [
        [{ :source => "tdc", :stable_id => 1, :path => "value", :libelle => "Ca va ?" }],
        [
          { :source => "tdc", :stable_id => 17, :path => "value", :libelle => "Commune" },
          { :source => "tdc", :stable_id => 17, :path => "code", :libelle => "Commune (Code INSEE)" },
          { :source => "tdc", :stable_id => 17, :path => "departement", :libelle => "Commune (Département)" }
        ],
        [{ :source => "tdc", :stable_id => 20, :path => "value", :libelle => "siret" }]
      ]
    end
  end

  describe '#all_repetable_tdc_columns' do
    xit "returns all repetable columns based upon procedure's type de champs" do
      expect(export_template.all_repetable_tdc_columns).to match_array [
        {
          :libelle => "Champ répétable",
         :types_de_champ =>  [
           [
             {
               :source => "repet",
              :repetition_champ_stable_id => 7,
              :path => "value",
              :stable_id => 8,
              :libelle => "Qqchose à rajouter?"
             }
           ]
         ]
        }
      ]
    end
  end

  describe '#all_usager_columns' do
    context 'for individual procedure' do
      let(:for_individual) { true }

      it "returns all usager columns" do
        expected = [
          procedure.find_column(label: "Nº dossier"),
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
          procedure.find_column(label: "Nº dossier"),
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

  describe '#columns and #repetable columns' do
    let(:tabular_export_template) { create(:export_template, kind: 'ods', content:, groupe_instructeur:) }
    let(:content) {
      {
        "columns" => [
          { :path => "email", :source => "dossier", :libelle => "Email" },
          { :path => "value", :source => "tdc", :libelle => "Ca va ?", "stable_id" => 1 },
          { :path => "code", :source => "tdc", :libelle => "Commune", "stable_id" => 2 },
          { :path => "value", :source => "repet", :libelle => "PJ répétable", "stable_id" => 4, "repetition_champ_stable_id" => 3 },
          { :path => "value", :source => "repet", :libelle => "Champ repetable", "stable_id" => 5, "repetition_champ_stable_id" => 3 },
          { :path => "value", :source => "repet", :libelle => "PJ", "stable_id" => 7, "repetition_champ_stable_id" => 6 }
        ]
      }
    }

    describe '#columns' do
      it 'returns all columns stored in export template' do
        expect(tabular_export_template.columns).to match_array [
          { :path => "email", :source => "dossier", :libelle => "Email" },
          { :path => "value", :source => "tdc", :libelle => "Ca va ?", :stable_id => 1 },
          { :path => "code", :source => "tdc", :libelle => "Commune", :stable_id => 2 },
          { :path => "value", :source => "repet", :libelle => "PJ répétable", :stable_id => 4, :repetition_champ_stable_id => 3 },
          { :path => "value", :source => "repet", :libelle => "Champ repetable", :stable_id => 5, :repetition_champ_stable_id => 3 },
          { :path => "value", :source => "repet", :libelle => "PJ", :stable_id => 7, :repetition_champ_stable_id => 6 }
        ]
      end
    end

    describe '#repetable_columns' do
      it 'returns repetable columns stored in export template grouped by repetition champ' do
        expect(tabular_export_template.repetable_columns).to eq(
          {
            3 => [
              { :path => "value", :source => "repet", :libelle => "PJ répétable", :stable_id => 4, :repetition_champ_stable_id => 3 },
              { :path => "value", :source => "repet", :libelle => "Champ repetable", :stable_id => 5, :repetition_champ_stable_id => 3 }
            ],
            6 => [
              { :path => "value", :source => "repet", :libelle => "PJ", :stable_id => 7, :repetition_champ_stable_id => 6 }
            ]
          }
        )
      end
    end
  end

  describe '#all_usager_columns' do
  end
end
