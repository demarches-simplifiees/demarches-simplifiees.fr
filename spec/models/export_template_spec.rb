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

  describe '#attachment_and_path' do
    let(:dossier) { create(:dossier) }

    context 'for export pdf' do
      let(:attachment) { double("attachment") }

      it 'gives absolute filename for export of specific dossier' do
        allow(attachment).to receive(:name).and_return('pdf_export_for_instructeur')
        expect(export_template.attachment_and_path(dossier, attachment)).to eq([attachment, "DOSSIER_#{dossier.id}/mon_export_#{dossier.id}.pdf"])
      end
    end
  end
end
