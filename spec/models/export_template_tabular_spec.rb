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
        expect(export_template.all_usager_columns).to match_array [
          { :path => "id", :source => "dossier", :libelle => "ID" },
          { :path => "email", :source => "dossier", :libelle => "Email" },
          { :path => "france_connecte", :source => "dossier", :libelle => "FranceConnect ?" },
          { :path => "civilite", :source => "dossier", :libelle => "Civilité" },
          { :path => "last_name", :source => "dossier", :libelle => "Nom" },
          { :path => "first_name", :source => "dossier", :libelle => "Prénom" },
          { :path => "for_tiers", :source => "dossier", :libelle => "Dépôt pour un tiers" },
          { :path => "mandataire_last_name", :source => "dossier", :libelle => "Nom du mandataire" },
          { :path => "mandataire_first_name", :source => "dossier", :libelle => "Prénom du mandataire" }
        ]

        expect(export_template.all_usager_columns.any? { _1[:path] == "etablissement_siret" }).to eq false
      end
    end

    context 'for entreprise procedure' do
      let(:for_individual) { false }

      it "returns all usager columns" do
        expect(export_template.all_usager_columns).to match_array [
          { :path => "id", :source => "dossier", :libelle => "ID" },
          { :path => "email", :source => "dossier", :libelle => "Email" },
          { :path => "france_connecte", :source => "dossier", :libelle => "FranceConnect ?" },
          { :path => "etablissement_siret", :source => "dossier", :libelle => "Établissement SIRET" },
          { :path => "etablissement_siege_social", :source => "dossier", :libelle => "Établissement siège social" },
          { :path => "etablissement_naf", :source => "dossier", :libelle => "Établissement NAF" },
          { :path => "etablissement_libelle_naf", :source => "dossier", :libelle => "Établissement libellé NAF" },
          { :path => "etablissement_adresse", :source => "dossier", :libelle => "Établissement Adresse" },
          { :path => "etablissement_numero_voie", :source => "dossier", :libelle => "Établissement numero voie" },
          { :path => "etablissement_type_voie", :source => "dossier", :libelle => "Établissement type voie" },
          { :path => "etablissement_nom_voie", :source => "dossier", :libelle => "Établissement nom voie" },
          { :path => "etablissement_complement_adresse", :source => "dossier", :libelle => "Établissement complément adresse" },
          { :path => "etablissement_code_postal", :source => "dossier", :libelle => "Établissement code postal" },
          { :path => "etablissement_localite", :source => "dossier", :libelle => "Établissement localité" },
          { :path => "etablissement_code_insee_localite", :source => "dossier", :libelle => "Établissement code INSEE localité" },
          { :path => "entreprise_siren", :source => "dossier", :libelle => "Entreprise SIREN" },
          { :path => "entreprise_capital_social", :source => "dossier", :libelle => "Entreprise capital social" },
          { :path => "entreprise_numero_tva_intracommunautaire", :source => "dossier", :libelle => "Entreprise numero TVA intracommunautaire" },
          { :path => "entreprise_forme_juridique", :source => "dossier", :libelle => "Entreprise forme juridique" },
          { :path => "entreprise_forme_juridique_code", :source => "dossier", :libelle => "Entreprise forme juridique code" },
          { :path => "entreprise_nom_commercial", :source => "dossier", :libelle => "Entreprise nom commercial" },
          { :path => "entreprise_raison_sociale", :source => "dossier", :libelle => "Entreprise raison sociale" },
          { :path => "entreprise_siret_siege_social", :source => "dossier", :libelle => "Entreprise SIRET siège social" },
          { :path => "entreprise_code_effectif_entreprise", :source => "dossier", :libelle => "Entreprise code effectif entreprise" }
        ]

        expect(export_template.all_usager_columns.any? { _1[:path] == "first_name" }).to eq false
      end
    end

    context 'when procedure chorusable' do
      before { expect_any_instance_of(Procedure).to receive(:chorusable?).and_return(true) }
      let(:procedure) { create(:procedure_with_dossiers, :filled_chorus, types_de_champ_public:) }
      it 'returns specific chorus columns' do
        allow(Procedure).to receive(:chorusable?).and_return(true)
        expect(export_template.all_usager_columns.include?({ :path => "domaine_fonctionnel", :source => "dossier", :libelle => "Domaine Fonctionnel" })).to be true
      end
    end
  end

  describe '#all_dossier_columns' do
    it "returns all dossier columns" do
      expect(export_template.all_dossier_columns).to match_array [
        { :path => "archived", :source => "dossier", :libelle => "Archivé" },
        { :path => "dossier_state", :source => "dossier", :libelle => "État du dossier" },
        { :path => "updated_at", :source => "dossier", :libelle => "Dernière mise à jour le" },
        { :path => "last_champ_updated_at", :source => "dossier", :libelle => "Dernière mise à jour du dossier le" },
        { :path => "depose_at", :source => "dossier", :libelle => "Déposé le" },
        { :path => "en_instruction_at", :source => "dossier", :libelle => "Passé en instruction le" },
        { :path => "processed_at", :source => "dossier", :libelle => "Traité le" },
        { :path => "motivation", :source => "dossier", :libelle => "Motivation de la décision" },
        { :path => "instructeurs", :source => "dossier", :libelle => "Instructeurs" },
        { :path => "groupe_instructeur", :source => "dossier", :libelle => "Groupe instructeur" }
      ]
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
