describe ExportTemplate do
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
  let(:export_template) { create(:export_template, :with_custom_content, groupe_instructeur:, content:) }
  let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public:, for_individual:) }
  let(:dossier) { procedure.dossiers.first }
  let(:for_individual) { false }
  let(:types_de_champ_public) do
    [
      { type: :piece_justificative, libelle: "Justificatif de domicile", mandatory: true, stable_id: 3 },
      { type: :titre_identite, libelle: "CNI", mandatory: true, stable_id: 5 }
    ]
  end
  let(:content) do
    {
      "pdf_name" => {
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "mon_export_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }
        ]
      },
      "default_dossier_directory" => {
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "DOSSIER_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " ", "type" => "text" }] }
        ]
      },
      "pjs" =>
      [
        { path: { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "mention", "attrs" => { "id" => "original-filename", "label" => "nom original du fichier" } }, { "text" => " _justif", "type" => "text" }] }] }, stable_id: "3" },
        {
          path:
                   { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "text" => "cni_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " ", "type" => "text" }] }] },
           stable_id: "5"
        },
        {
          path: { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "text" => "pj_repet_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " ", "type" => "text" }] }] },
         stable_id: "10"
        }
      ]
    }
  end

  describe 'new' do
    let(:export_template) { build(:export_template, groupe_instructeur: groupe_instructeur) }
    it 'set default values' do
      export_template.set_default_values
      expect(export_template.content).to eq({
        "pdf_name" => {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [{ "text" => "export_", "type" => "text" }, { "type" => "mention", "attrs" => ExportTemplate::DOSSIER_ID_TAG.stringify_keys }] }
          ]
        },
        "default_dossier_directory" => {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [{ "text" => "dossier-", "type" => "text" }, { "type" => "mention", "attrs" => ExportTemplate::DOSSIER_ID_TAG.stringify_keys }] }
          ]
        },
        "pjs" =>
        [

          {
            "stable_id" => "3",
            "path" =>  { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "text" => "justificatif-de-domicile-", "type" => "text" }, { "type" => "mention", "attrs" => ExportTemplate::DOSSIER_ID_TAG.stringify_keys }] }] }
          }
        ]
      })
    end
  end

  describe '#assign_pj_names' do
    let(:pj_params) do
      {
        "tiptap_pj_1" => {
          "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "avis-commission-" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }]
        }.to_json
      }
    end
    it 'values content from pj params' do
      export_template.assign_pj_names(pj_params)
      expect(export_template.content["pjs"]).to eq [
        { :path => { "content" => [{ "content" => [{ "text" => "avis-commission-", "type" => "text" }, { "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" }, "type" => "mention" }], "type" => "paragraph" }], "type" => "doc" }, :stable_id => "1" }
      ]
    end
  end

  describe '#tiptap_default_dossier_directory' do
    it 'returns tiptap_default_dossier_directory from content' do
      expect(export_template.tiptap_default_dossier_directory).to eq({
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "DOSSIER_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " ", "type" => "text" }] }
        ]
      }.to_json)
    end
  end

  describe '#tiptap_pdf_name' do
    it 'returns tiptap_pdf_name from content' do
      expect(export_template.tiptap_pdf_name).to eq({
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "mon_export_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }
        ]
      }.to_json)
    end
  end

  describe '#content_for_pj' do
    let(:type_de_champ_pj) { create(:type_de_champ_piece_justificative, stable_id: 3, libelle: 'Justificatif de domicile', procedure:) }
    let(:champ_pj) { create(:champ_piece_justificative, type_de_champ: type_de_champ_pj) }

    let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

    it 'returns tiptap content for pj' do
      expect(export_template.content_for_pj(type_de_champ_pj)).to eq({
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "mention", "attrs" => { "id" => "original-filename", "label" => "nom original du fichier" } }, { "text" => " _justif", "type" => "text" }] }
        ]
      }.to_json)
    end
  end

  describe '#attachment_and_path' do
    let(:dossier) { create(:dossier) }

    context 'for export pdf' do
      let(:attachment) { double("attachment") }

      it 'gives absolute filename for export of specific dossier' do
        allow(attachment).to receive(:name).and_return('pdf_export_for_instructeur')
        expect(export_template.attachment_and_path(dossier, attachment)).to eq([attachment, "DOSSIER_#{dossier.id}/mon_export_#{dossier.id}.pdf"])
      end
    end

    context 'for pj' do
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champ_pj) { dossier.champs.find { |c| c.type == 'Champs::PieceJustificativeChamp' } }
      let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

      it 'returns pj and custom name for pj' do
        expect(export_template.attachment_and_path(dossier, attachment, champ: champ_pj)).to eq([attachment, "DOSSIER_#{dossier.id}/superpj_justif-1.png"])
      end
    end
    context 'pj repetable' do
      let(:procedure) { create(:procedure, :for_individual, types_de_champ_public:) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:draft) { procedure.draft_revision }
      let(:types_de_champ_public) do
        [
          {
            type: :repetition,
            stable_id: 3333,
            mandatory: true, children: [
              { type: :text, libelle: 'sub type de champ' },
              { type: :piece_justificative, stable_id: 10, libelle: 'pj repet' }
            ]
          }
        ]
      end
      let(:champ_pj) { dossier.champs.find(&:piece_justificative?) }
      let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

      it 'rename repetable pj' do
        expect(export_template.attachment_and_path(dossier, attachment, champ: champ_pj)).to eq([attachment, "DOSSIER_#{dossier.id}/pj_repet_#{dossier.id}-1.png"])
      end
    end
  end

  describe '#tiptap_convert' do
    it 'convert default dossier directory' do
      expect(export_template.tiptap_convert(procedure.dossiers.first, "default_dossier_directory")).to eq "DOSSIER_#{dossier.id}"
    end

    it 'convert pdf_name' do
      expect(export_template.tiptap_convert(procedure.dossiers.first, "pdf_name")).to eq "mon_export_#{dossier.id}"
    end

    context 'for date' do
      let(:export_template) { create(:export_template, :with_date_depot_for_export_pdf, groupe_instructeur:) }
      let(:dossier) { create(:dossier, :en_construction, procedure:, depose_at: Date.parse("2024/03/30")) }
      it 'convert date with dash' do
        expect(export_template.tiptap_convert(dossier, "pdf_name")).to eq "export_#{dossier.id}-2024-03-30"
      end
    end
  end

  describe '#tiptap_convert_pj' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, stable_id: 3, libelle: 'Justificatif de domicile' }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ_pj) { dossier.champs.first }
    let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

    it 'convert pj' do
      attachment
      expect(export_template.tiptap_convert_pj(dossier, 3, attachment)).to eq "superpj_justif"
    end
  end

  describe '#valid?' do
    let(:subject) { build(:export_template, groupe_instructeur:, content:) }
    let(:ddd_text) { "DoSSIER" }
    let(:mention) { { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } } }
    let(:ddd_mention) { mention }
    let(:pdf_text) { "export" }
    let(:pdf_mention) { mention }
    let(:pj_text) { "_pj" }
    let(:pj_mention) { mention }
    let(:content) do
      {
        "pdf_name" => {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [{ "text" => pdf_text, "type" => "text" }, pdf_mention] }
          ]
        },
        "default_dossier_directory" => {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [{ "text" => ddd_text, "type" => "text" }, ddd_mention] }
          ]
        },
        "pjs" =>
        [
          { path: { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [pj_mention, { "text" => pj_text, "type" => "text" }] }] }, stable_id: "3" }
        ]
      }
    end

    context 'with valid default dossier directory' do
      it 'has no error for default_dossier_directory' do
        expect(subject.valid?).to be_truthy
      end
    end

    context 'with no ddd text' do
      let(:ddd_text) { " " }
      context 'with mention' do
        let(:ddd_mention) { { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } } }
        it 'has no error for default_dossier_directory' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'without numéro de dossier' do
        let(:ddd_mention) { { "type" => "mention", "attrs" => { "id" => 'dossier_service_name', "label" => "nom du service" } } }
        it "add error for tiptap_default_dossier_directory" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:tiptap_default_dossier_directory]).to be_present
          expect(subject.errors.full_messages).to include "Le champ « Nom du répertoire » doit contenir le numéro du dossier"
        end
      end
    end

    context 'with valid pdf name' do
      it 'has no error for pdf name' do
        expect(subject.valid?).to be_truthy
        expect(subject.errors[:tiptap_pdf_name]).not_to be_present
      end
    end

    context 'with pdf text and without mention' do
      let(:pdf_text) { "export" }
      let(:pdf_mention) { { "type" => "mention", "attrs" => {} } }

      it "add no error" do
        expect(subject.valid?).to be_truthy
      end
    end

    context 'with no pdf text' do
      let(:pdf_text) { " " }

      context 'with mention' do
        it 'has no error for default_dossier_directory' do
          expect(subject.valid?).to be_truthy
          expect(subject.errors[:tiptap_pdf_name]).not_to be_present
        end
      end

      context 'without mention' do
        let(:pdf_mention) { { "type" => "mention", "attrs" => {} } }
        it "add error for pdf name" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors.full_messages).to include "Le champ « Nom du dossier au format pdf » doit être rempli"
        end
      end
    end

    context 'with no pj text' do
      # let!(:type_de_champ_pj) { create(:type_de_champ_piece_justificative, stable_id: 3, libelle: 'Justificatif de domicile', procedure:) }
      let(:pj_text) { " " }

      context 'with mention' do
        it 'has no error for pj' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'without mention' do
        let(:pj_mention) { { "type" => "mention", "attrs" => {} } }
        it "add error for pj" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors.full_messages).to include "Le champ « Justificatif de domicile » doit être rempli"
        end
      end
    end
  end

  context 'for entreprise procedure' do
    let(:for_individual) { false }
    describe 'specific_tags' do
      it do
        tags = export_template.specific_tags
        expect(tags.map { _1[:id] }).to eq ["entreprise_siren", "entreprise_numero_tva_intracommunautaire", "entreprise_siret_siege_social", "entreprise_raison_sociale", "entreprise_adresse", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur"]
      end
    end

    describe 'tags_for_pj' do
      it do
        tags = export_template.tags_for_pj
        expect(tags.map { _1[:id] }).to eq ["entreprise_siren", "entreprise_numero_tva_intracommunautaire", "entreprise_siret_siege_social", "entreprise_raison_sociale", "entreprise_adresse", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur", "original-filename"]
      end
    end
  end

  context 'for individual procedure' do
    let(:for_individual) { true }
    describe 'specific_tags' do
      it do
        tags = export_template.specific_tags
        expect(tags.map { _1[:id] }).to eq ["individual_gender", "individual_last_name", "individual_first_name", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur"]
      end
    end

    describe 'tags_for_pj' do
      it do
        tags = export_template.tags_for_pj
        expect(tags.map { _1[:id] }).to eq ["individual_gender", "individual_last_name", "individual_first_name", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur", "original-filename"]
      end
    end
  end
end
