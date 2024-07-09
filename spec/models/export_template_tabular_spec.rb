describe ExportTemplate do
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
  let(:export_template) { build(:export_template, groupe_instructeur:) }
  let(:tabular_export_template) { build(:tabular_export_template, groupe_instructeur:) }
  let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public:, for_individual:) }
  let(:for_individual) { true }
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: "Ca va ?", mandatory: true, stable_id: 1 },
      { type: :communes, libelle: "Commune", mandatory: true, stable_id: 17 },
      { type: :siret, libelle: 'siret', stable_id: 20 },
      { type: :repetition, mandatory: true, stable_id: 7, libelle: "Champ répétable", children: [{ type: 'text', libelle: 'Qqchose à rajouter?', stable_id: 8 }] }
    ]
  end
  let(:dossier) { procedure.dossiers.first }

  describe '#paths=' do
    let(:paths) { ["dossier_id", "dossier_email", "dossier_archived", "dossier_dossier_state", "tdc_1_value", "tdc_17_value", "tdc_17_code", "repet_7_tdc_8_value"] }

    it 'update columns when assiging paths' do
      export_template.paths = paths
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

    it 'returns paths from columns' do
      expect(tabular_export_template.paths).to match_array ["dossier_email", "tdc_1_value", "tdc_2_code", "repet_3_tdc_4_value", "repet_3_tdc_5_value", "repet_6_tdc_7_value"]
    end
  end

  describe '#all_tdc_paths' do
    it "returns all tdc paths (without repetition) based upon procedure's type de champs" do
      expect(export_template.all_tdc_paths.flatten.find { _1.full_path == "tdc_1_value" }.libelle).to eq "Ca va ?"
      expect(export_template.all_tdc_paths.flatten.find { _1.full_path == "tdc_17_code" }.libelle).to eq "Commune (Code INSEE)"
      expect(export_template.all_tdc_paths.flatten.find { _1.full_path == "tdc_20_value" }.libelle).to eq "siret"
      expect(export_template.all_tdc_paths.flatten.any? { _1.full_path.starts_with?("repet") }).to be false
    end
  end

  describe '#all_repetable_tdc_paths' do
    it "returns all repetable paths based upon procedure's type de champs" do
      rtdc_path = export_template.all_repetable_tdc_paths[0]
      tdc_path = rtdc_path[:types_de_champ][0]
      expect(rtdc_path[:libelle]).to eq "Champ répétable"
      expect(tdc_path[0].full_path).to eq "repet_7_tdc_8_value"
      expect(tdc_path[0].libelle).to eq "Qqchose à rajouter?"
    end
  end

  describe '#all_usager_paths' do
    context 'for individual procedure' do
      let(:for_individual) { true }

      it "returns all usager paths" do
        all_usager_paths = export_template.all_usager_paths
        expect(all_usager_paths.find { _1.full_path == "dossier_first_name" }.libelle).to eq 'Prénom'
        expect(all_usager_paths.find { _1.full_path == "dossier_last_name" }.libelle).to eq 'Nom'
        expect(all_usager_paths.any? { _1.full_path == "dossier_etablissement_siret" }).to eq false
      end
    end

    context 'for entreprise procedure' do
      let(:for_individual) { false }

      it "returns all usager paths" do
        all_usager_paths = export_template.all_usager_paths
        expect(all_usager_paths.find { _1.full_path == "dossier_etablissement_siret" }.libelle).to eq 'Établissement SIRET'
        expect(all_usager_paths.find { _1.full_path == "dossier_entreprise_raison_sociale" }.libelle).to eq 'Entreprise raison sociale'
        expect(all_usager_paths.any? { _1.full_path == "dossier_first_name" }).to eq false
      end
    end

    context 'when ask birthday' do
      let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public:, for_individual:, ask_birthday: true) }
      it 'returns date de naissance column' do
        expect(export_template.all_usager_paths.find { _1.full_path == "dossier_date_de_naissance" }.libelle).to eq "Date de naissance"
      end
    end

    context 'when procedure chorusable' do
      before { expect_any_instance_of(Procedure).to receive(:chorusable?).and_return(true) }
      let(:procedure) { create(:procedure_with_dossiers, :filled_chorus, types_de_champ_public:) }
      it 'returns specific chorus columns' do
        allow(Procedure).to receive(:chorusable?).and_return(true)
        expect(export_template.all_usager_paths.find { _1.full_path == "dossier_domaine_fonctionnel" }.libelle).to eq "Domaine Fonctionnel"
      end
    end
  end

  describe '#all_dossier_paths' do
    it "returns all dossier paths" do
      all_dossier_paths = export_template.all_dossier_paths
      # expect(all_dossier_paths).to eq 'coucou'
      expect(all_dossier_paths.find { _1.full_path == "dossier_updated_at" }.libelle).to eq 'Dernière mise à jour le'
    end
  end

  describe '#columns' do
    it 'returns all columns stored in export template' do
      expect(tabular_export_template.columns).to match_array [
        { "path" => "email", "source" => "dossier", "libelle" => "Email" },
        { "path" => "value", "source" => "tdc", "libelle" => "Ca va ?", "stable_id" => 1 },
        { "path" => "code", "source" => "tdc", "libelle" => "Commune", "stable_id" => 2 },
        { "path" => "value", "source" => "repet", "libelle" => "PJ répétable", "stable_id" => 4, "repetition_champ_stable_id" => 3 },
        { "path" => "value", "source" => "repet", "libelle" => "Champ repetable", "stable_id" => 5, "repetition_champ_stable_id" => 3 },
        { "path" => "value", "source" => "repet", "libelle" => "PJ", "stable_id" => 7, "repetition_champ_stable_id" => 6 }
      ]
    end
  end

  describe '#repetable_columns' do
    it 'returns repetable columns stored in export template grouped by repetition champ' do
      expect(tabular_export_template.repetable_columns).to eq(
        {
          3 => [
            { "path" => "value", "source" => "repet", "libelle" => "PJ répétable", "stable_id" => 4, "repetition_champ_stable_id" => 3 },
            { "path" => "value", "source" => "repet", "libelle" => "Champ repetable", "stable_id" => 5, "repetition_champ_stable_id" => 3 }
          ],
          6 => [
            { "path" => "value", "source" => "repet", "libelle" => "PJ", "stable_id" => 7, "repetition_champ_stable_id" => 6 }
          ]
        }
      )
    end
  end

  describe '#all_usager_columns' do
  end
end
