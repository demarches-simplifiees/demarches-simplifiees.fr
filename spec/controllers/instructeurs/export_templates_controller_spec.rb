describe Instructeurs::ExportTemplatesController, type: :controller do
  before { sign_in(instructeur.user) }
  let(:tiptap_pdf_name) {
    {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "text" => "mon_export_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }
      ]
    }.to_json
  }

  let(:export_template_params) do
    {
      name: "coucou",
      kind: "zip",
      groupe_instructeur_id: groupe_instructeur.id,
      tiptap_pdf_name: tiptap_pdf_name,
      tiptap_default_dossier_directory: {
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "DOSSIER_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " ", "type" => "text" }] }
        ]
      }.to_json,
      "pjs" =>
      [
        { path: { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " _justif", "type" => "text" }] }] }, stable_id: "3" },
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

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
  let(:groupe_instructeur) { procedure.defaut_groupe_instructeur }

  describe '#create' do
    let(:subject) { post :create, params: { procedure_id: procedure.id, export_template: export_template_params } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export coucou a bien été créé"
      end
    end

    context 'with invalid params' do
      let(:tiptap_pdf_name) { { content: "invalid" }.to_json }
      it 'display error notification' do
        subject
        expect(flash.alert).to be_present
      end
    end

    context 'with procedure not accessible by current instructeur' do
      let(:another_procedure) { create(:procedure) }
      let(:subject) { post :create, params: { procedure_id: another_procedure.id, export_template: export_template_params } }
      it 'raise exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#edit' do
    let(:export_template) { create(:export_template, groupe_instructeur:) }
    let(:subject) { get :edit, params: { procedure_id: procedure.id, id: export_template.id } }

    it 'render edit' do
      subject
      expect(response).to render_template(:edit)
    end

    context "with export_template not accessible by current instructeur" do
      let(:another_groupe_instructeur) { create(:groupe_instructeur) }
      let(:export_template) { create(:export_template, groupe_instructeur: another_groupe_instructeur) }

      it 'raise exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update' do
    let(:export_template) { create(:export_template, groupe_instructeur:) }
    let(:tiptap_pdf_name) {
      {
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "exPort_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }
        ]
      }.to_json
    }

    let(:subject) { put :update, params: { procedure_id: procedure.id, id: export_template.id, export_template: export_template_params } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export coucou a bien été modifié"
      end
    end

    context 'with invalid params' do
      let(:tiptap_pdf_name) { { content: "invalid" }.to_json }
      it 'display error notification' do
        subject
        expect(flash.alert).to be_present
      end
    end
  end

  describe '#destroy' do
    let(:export_template) { create(:export_template, groupe_instructeur:) }
    let(:subject) { delete :destroy, params: { procedure_id: procedure.id, id: export_template.id } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export Mon export a bien été supprimé"
      end
    end
  end
end
