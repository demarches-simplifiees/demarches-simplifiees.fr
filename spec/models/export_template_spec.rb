describe ExportTemplate do
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
  let(:export_template) { build(:export_template, groupe_instructeur:, content:) }
  let(:procedure) { create(:procedure_with_dossiers) }
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
        {path: {"type"=>"doc", "content"=>[{"type"=>"paragraph", "content"=>[{"type"=>"mention", "attrs"=>{"id"=>"dossier_number", "label"=>"numéro du dossier"}}, {"text"=>" _justif", "type"=>"text"}]}]}, stable_id: "3"},
        { path:
         {"type"=>"doc", "content"=>[{"type"=>"paragraph", "content"=>[{"text"=>"cni_", "type"=>"text"}, {"type"=>"mention", "attrs"=>{"id"=>"dossier_number", "label"=>"numéro du dossier"}}, {"text"=>" ", "type"=>"text"}]}]},
           stable_id: "5"},
           { path: {"type"=>"doc", "content"=>[{"type"=>"paragraph", "content"=>[{"text"=>"pj_repet_", "type"=>"text"}, {"type"=>"mention", "attrs"=>{"id"=>"dossier_number", "label"=>"numéro du dossier"}}, {"text"=>" ", "type"=>"text"}]}]},
            stable_id: "10"}
      ]
    }
  end

  describe 'new' do
    let(:export_template) { build(:export_template, groupe_instructeur: groupe_instructeur) }
    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:types_de_champ_public) do
      [
        { type: :integer_number, stable_id: 900 },
        { type: :piece_justificative, libelle: "Justificatif de domicile", mandatory: true, stable_id: 910 }
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
        "type"=>"doc",
        "content"=> [
          {"type"=>"paragraph", "content"=>[{"type"=>"mention", "attrs"=>{"id"=>"dossier_number", "label"=>"numéro du dossier"}}, {"text"=>" _justif", "type"=>"text"}]}
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
      let(:dossier) { procedure.dossiers.first }
      let(:type_de_champ_pj) { create(:type_de_champ_piece_justificative, stable_id: 3, procedure:) }
      let(:champ_pj) { create(:champ_piece_justificative, type_de_champ: type_de_champ_pj) }

      let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

      before do
        dossier.champs_public << champ_pj
      end
      it 'returns pj and custom name for pj' do
        expect(export_template.attachment_and_path(dossier, attachment)).to eq([attachment, "DOSSIER_#{dossier.id}/#{dossier.id}_justif.png"])
      end
    end
    context 'pj repetable' do
      let(:procedure) do
        create(:procedure_with_dossiers, :for_individual, types_de_champ_public: [{ type: :repetition, mandatory: true, children: [{ libelle: 'sub type de champ' }] }])
      end
      let(:type_de_champ_repetition) do
        repetition = draft.types_de_champ_public.repetition.first
        repetition.update(stable_id: 3333)
        repetition
      end
      let(:draft) { procedure.draft_revision }
      let(:dossier) { procedure.dossiers.first }

      let(:type_de_champ_pj) do
        draft.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:piece_justificative),
          libelle: "pj repet",
          stable_id: 10,
          parent_stable_id: type_de_champ_repetition.stable_id
        })
      end
      let(:champ_pj) { create(:champ_piece_justificative, type_de_champ: type_de_champ_pj) }

      let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

      before do
        dossier.champs_public << champ_pj
      end
      it 'rename repetable pj' do
        expect(export_template.attachment_and_path(dossier, attachment)).to eq([attachment, "DOSSIER_#{dossier.id}/pj_repet_#{dossier.id}.png"])
      end
    end
  end
end
