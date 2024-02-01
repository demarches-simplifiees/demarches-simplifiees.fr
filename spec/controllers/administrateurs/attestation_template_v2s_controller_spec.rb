describe Administrateurs::AttestationTemplateV2sController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:attestation_template) { build(:attestation_template, :v2) }
  let!(:procedure) { create(:procedure, administrateur: admin, attestation_template: attestation_template, libelle: "Ma démarche") }
  let(:logo) { fixture_file_upload('spec/fixtures/files/white.png', 'image/png') }
  let(:signature) { fixture_file_upload('spec/fixtures/files/black.png', 'image/png') }

  let(:update_params) do
    {
      official_layout: true,
      label_logo: "Ministère des specs",
      label_direction: "RSPEC",
      footer: "en bas",
      activated: false,
      tiptap_body: {
        type: :doc,
        content: [
          {
            type: :paragraph,
            content: [{ text: "Yo from spec", type: :text }]
          }
        ]
      }.to_json
    }
  end

  before do
    sign_in(admin.user)
    Flipper.enable(:attestation_v2)
  end

  describe 'GET #show' do
    subject do
      get :show, params: { procedure_id: procedure.id }
      response.body
    end

    context 'if an attestation template exists on the procedure' do
      render_views

      context 'with preview dossier' do
        let!(:dossier) { create(:dossier, :en_construction, procedure:, for_procedure_preview: true) }

        it do
          is_expected.to include("Mon titre pour Ma démarche")
          is_expected.to include("n° #{dossier.id}")
        end
      end

      context 'without preview dossier' do
        it do
          is_expected.to include("Mon titre pour --dossier_procedure_libelle--")
        end
      end

      context 'with logo label' do
        it do
          is_expected.to include("Ministère des devs")
          is_expected.to match(/centered_marianne-\w+\.svg/)
        end
      end

      context 'with label direction' do
        let(:attestation_template) { build(:attestation_template, :v2, label_direction: "calé à droite") }

        it do
          is_expected.to include("calé à droite")
        end
      end

      context 'with footer' do
        let(:attestation_template) { build(:attestation_template, :v2, footer: "c'est le pied") }

        it do
          is_expected.to include("c'est le pied")
        end
      end

      context 'with additional logo' do
        let(:attestation_template) { build(:attestation_template, :v2, logo:) }

        it do
          is_expected.to include("Ministère des devs")
          is_expected.to include("white.png")
        end
      end

      context 'with signature' do
        let(:attestation_template) { build(:attestation_template, :v2, signature:) }

        it do
          is_expected.to include("black.png")
        end
      end
    end
  end

  describe 'GET edit' do
    subject do
      get :edit, params: { procedure_id: procedure.id }
      response.body
    end

    context 'if an attestation template does not exists yet on the procedure' do
      let(:attestation_template) { nil }

      it 'creates new v2 attestation template' do
        subject
        expect(assigns(:attestation_template).version).to eq(2)
      end
    end

    context 'if an attestation template already exist on v1' do
      let(:attestation_template) { build(:attestation_template, version: 1) }

      it 'build new v2 attestation template' do
        subject
        expect(assigns(:attestation_template).version).to eq(2)
      end
    end

    context 'if attestation template already exist on v2' do
      it 'assigns v2 attestation template' do
        subject
        expect(assigns(:attestation_template)).to eq(attestation_template)
      end
    end
  end

  describe 'POST create' do
    let(:attestation_template) { nil }

    subject do
      post :create, params: { procedure_id: procedure.id, attestation_template: update_params }, format: :turbo_stream
      response.body
    end

    context 'when attestation template is valid' do
      render_views

      it "create template" do
        subject
        attestation_template = procedure.reload.attestation_template

        expect(attestation_template.official_layout).to eq(true)
        expect(attestation_template.label_logo).to eq("Ministère des specs")
        expect(attestation_template.label_direction).to eq("RSPEC")
        expect(attestation_template.footer).to eq("en bas")
        expect(attestation_template.activated).to eq(false)
        expect(attestation_template.tiptap_body).to eq(update_params[:tiptap_body])

        expect(response.body).to include("Formulaire enregistré")
      end

      context "with files" do
        let(:update_params) { super().merge(logo:, signature:) }

        it "upload files" do
          subject
          attestation_template = procedure.reload.attestation_template

          expect(attestation_template.logo.download).to eq(logo.read)
          expect(attestation_template.signature.download).to eq(signature.read)
        end
      end
    end
  end

  describe 'PATCH update' do
    render_views
    subject do
      patch :update, params: { procedure_id: procedure.id, attestation_template: update_params }, format: :turbo_stream
      response.body
    end

    context 'when attestation template is valid' do
      it "update template" do
        subject
        attestation_template.reload

        expect(attestation_template.official_layout).to eq(true)
        expect(attestation_template.label_logo).to eq("Ministère des specs")
        expect(attestation_template.label_direction).to eq("RSPEC")
        expect(attestation_template.footer).to eq("en bas")
        expect(attestation_template.activated).to eq(false)
        expect(attestation_template.tiptap_body).to eq(update_params[:tiptap_body])

        expect(response.body).to include("Formulaire enregistré")
      end

      context "with files" do
        let(:update_params) { super().merge(logo:, signature:) }

        it "upload files" do
          subject
          attestation_template.reload

          expect(attestation_template.logo.download).to eq(logo.read)
          expect(attestation_template.signature.download).to eq(signature.read)
        end
      end

      context 'with error' do
        let(:update_params) do
          super().merge(tiptap_body: { type: :doc, content: [{ type: :mention, attrs: { id: "tdc12", label: "oops" } }] }.to_json)
        end

        it "render error" do
          subject
          expect(response.body).to include("Formulaire en erreur")
          expect(response.body).to include('Supprimer cette balise')
        end
      end
    end
  end
end
