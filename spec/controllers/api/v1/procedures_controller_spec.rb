describe API::V1::ProceduresController, type: :controller do
  let!(:admin) { create(:administrateur, :with_api_token) }
  let!(:token) { admin.renew_api_token }

  it { expect(described_class).to be < APIController }

  describe 'GET show' do
    subject { get :show, params: { id: procedure_id, token: token } }

    context 'when procedure does not exist' do
      let(:procedure_id) { 999_999_999 }

      it { is_expected.to have_http_status(404) }
    end

    context 'when procedure belongs to administrateur without token' do
      let(:procedure_id) { create(:procedure).id }

      it { is_expected.to have_http_status(401) }
    end

    context 'when procedure exist' do
      let(:procedure_id) { create(:procedure, administrateur: admin).id }

      it { is_expected.to have_http_status(200) }

      describe 'body' do
        let(:module_api_carto) { create(:module_api_carto, use_api_carto: true, quartiers_prioritaires: true, cadastre: true) }
        let(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative, module_api_carto: module_api_carto, administrateur: admin) }
        let(:response) { get :show, params: { id: procedure.id, token: token } }

        subject { JSON.parse(response.body, symbolize_names: true)[:procedure] }

        it { expect(subject[:id]).to eq(procedure.id) }
        it { expect(subject[:label]).to eq(procedure.libelle) }
        it { expect(subject[:description]).to eq(procedure.description) }
        it { expect(subject[:organisation]).to eq(procedure.organisation) }
        it { expect(subject[:direction]).to eq(procedure.direction) }
        it { expect(subject[:link]).to eq(procedure.lien_demarche) }
        it { expect(subject[:archived_at]).to eq(procedure.archived_at) }
        it { expect(subject[:total_dossier]).to eq(procedure.total_dossier) }
        it { is_expected.to have_key(:types_de_champ) }
        it { expect(subject[:types_de_champ]).to be_an(Array) }

        describe 'type_de_champ' do
          subject { super()[:types_de_champ][0] }

          let(:champ) { procedure.types_de_champ.first }

          it { expect(subject[:id]).to eq(champ.id) }
          it { expect(subject[:libelle]).to eq(champ.libelle) }
          it { expect(subject[:type_champ]).to eq(champ.type_champ) }
          it { expect(subject[:order_place]).to eq(champ.order_place) }
          it { expect(subject[:description]).to eq(champ.description) }
        end

        it { is_expected.to have_key(:types_de_piece_justificative) }
        it { expect(subject[:types_de_piece_justificative]).to be_an(Array) }

        describe 'type_de_piece_jointe' do
          subject { super()[:types_de_piece_justificative][0] }

          let(:pj) { procedure.types_de_piece_justificative.first }

          it { expect(subject[:id]).to eq(pj.id) }
          it { expect(subject[:libelle]).to eq(pj.libelle) }
          it { expect(subject[:description]).to eq(pj.description) }
        end

        it { is_expected.to have_key(:geographic_information) }

        describe 'geographic_information' do
          subject { super()[:geographic_information] }

          it { expect(subject[:use_api_carto]).to be_truthy }
          it { expect(subject[:quartiers_prioritaires]).to be_truthy }
          it { expect(subject[:cadastre]).to be_truthy }
        end
      end
    end
  end
end
