describe Administrateurs::AttestationTemplateV2sController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:attestation_template) { build(:attestation_template, :v2) }
  let!(:procedure) { create(:procedure, administrateur: admin, attestation_template: attestation_template, libelle: "Ma démarche") }
  let(:logo) { fixture_file_upload('spec/fixtures/files/white.png', 'image/png') }
  let(:signature) { fixture_file_upload('spec/fixtures/files/black.png', 'image/png') }

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
end
