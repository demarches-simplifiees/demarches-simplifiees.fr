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

  let(:export_template_zip_params) do
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
      tiptap_pj_3: {
        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "avis-commission-" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }]
      }.to_json,
      tiptap_pj_5: {

        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "avis-commission-" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }]
      }.to_json,
      tiptap_pj_10: {

        "type" => "doc",
        "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "avis-commission-" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }]
      }.to_json
    }
  end

  let(:paths) { ["dossier_id", "dossier_email", "dossier_updated_at", "tdc_1_value"] }
  let(:export_template_tabular_params) do
    {
      name: "ExportODS",
      kind: "ods",
      groupe_instructeur_id: groupe_instructeur.id,
      paths: paths
    }
  end

  let(:instructeur) { create(:instructeur) }
  let(:procedure) do
    create(
      :procedure, instructeurs: [instructeur],
      types_de_champ_public: [
        { type: :text, libelle: "Comment allez-vous ?", stable_id: 1 },
        { type: :piece_justificative, libelle: "pj1", stable_id: 3 },
        { type: :piece_justificative, libelle: "pj2", stable_id: 5 },
        { type: :piece_justificative, libelle: "pj3", stable_id: 10 }
      ]
    )
  end
  let(:groupe_instructeur) { procedure.defaut_groupe_instructeur }

  describe '#new' do
    let(:subject) { get :new, params: { procedure_id: procedure.id } }

    it do
      subject
      expect(assigns(:export_template)).to be_present
    end
  end

  describe '#create' do
    context 'with zip params' do
      let(:subject) { post :create, params: { procedure_id: procedure.id, export_template: export_template_zip_params } }
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
        let(:subject) { post :create, params: { procedure_id: another_procedure.id, export_template: export_template_zip_params } }
        it 'raise exception' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'with tabular params' do
      let(:subject) { post :create, params: { procedure_id: procedure.id, export_template: export_template_tabular_params } }
      context 'with valid params' do
        it 'redirect to some page' do
          subject
          expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
          expect(flash.notice).to eq "Le modèle d'export ExportODS a bien été créé"
        end
      end
    end
  end

  describe '#edit' do
    let(:export_template) { create(:zip_export_template, groupe_instructeur:) }
    let(:subject) { get :edit, params: { procedure_id: procedure.id, id: export_template.id } }

    it 'render edit' do
      subject
      expect(response).to render_template(:edit)
    end

    context "with export_template not accessible by current instructeur" do
      let(:another_groupe_instructeur) { create(:groupe_instructeur) }
      let(:export_template) { create(:zip_export_template, groupe_instructeur: another_groupe_instructeur) }

      it 'raise exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update' do
    context 'for zip' do
      let(:export_template) { create(:zip_export_template, groupe_instructeur:) }

      let(:tiptap_pdf_name) {
        {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [{ "text" => "exPort_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }
          ]
        }.to_json
      }

      let(:subject) { put :update, params: { procedure_id: procedure.id, id: export_template.id, export_template: export_template_zip_params } }

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

    context 'for tabular' do
      let(:export_template) { create(:tabular_export_template, groupe_instructeur:) }
      let(:paths) { ["dossier_id", "dossier_email", "dossier_updated_at"] }
      let(:subject) { put :update, params: { procedure_id: procedure.id, id: export_template.id, export_template: export_template_tabular_params } }

      context 'with valid params' do
        it 'redirect to some page' do
          subject
          expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
          expect(flash.notice).to eq "Le modèle d'export ExportODS a bien été modifié"
        end
      end
    end
  end

  describe '#destroy' do
    let(:export_template) { create(:zip_export_template, groupe_instructeur:) }
    let(:subject) { delete :destroy, params: { procedure_id: procedure.id, id: export_template.id } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export Mon export a bien été supprimé"
      end
    end
  end

  describe '#preview' do
    render_views

    let(:export_template) { create(:zip_export_template, groupe_instructeur:) }

    let(:subject) { get :preview, params: { procedure_id: procedure.id, id: export_template.id, export_template: export_template_zip_params }, format: :turbo_stream }

    it '' do
      dossier = create(:dossier, procedure: procedure, for_procedure_preview: true)
      subject
      expect(response.body).to include "DOSSIER_#{dossier.id}"
      expect(response.body).to include "mon_export_#{dossier.id}.pdf"
    end
  end
end
