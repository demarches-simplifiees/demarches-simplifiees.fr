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
        let(:procedure) { create(:procedure, :with_type_de_champ, :with_service, administrateur: admin) }
        let(:response) { get :show, params: { id: procedure.id, token: token } }

        subject { JSON.parse(response.body, symbolize_names: true)[:procedure] }

        it { expect(subject[:id]).to eq(procedure.id) }
        it { expect(subject[:label]).to eq(procedure.libelle) }
        it { expect(subject[:description]).to eq(procedure.description) }
        it { expect(subject[:organisation]).to eq(procedure.organisation) }
        it { expect(subject[:archived_at]).to eq(procedure.closed_at) }
        it { expect(subject[:total_dossier]).to eq(procedure.total_dossier) }
        it { is_expected.to have_key(:types_de_champ) }
        it { expect(subject[:types_de_champ]).to be_an(Array) }

        describe 'type_de_champ' do
          subject { super()[:types_de_champ][0] }

          let(:champ) { procedure.types_de_champ.first }

          it { expect(subject[:id]).to eq(champ.id) }
          it { expect(subject[:libelle]).to eq(champ.libelle) }
          it { expect(subject[:type_champ]).to eq(champ.type_champ) }
          it { expect(subject[:description]).to eq(champ.description) }
        end

        describe 'service' do
          subject { super()[:service] }

          let(:service) { procedure.service }

          it { expect(subject[:id]).to eq(service.id) }
          it { expect(subject[:email]).to eq(service.email) }
          it { expect(subject[:name]).to eq(service.nom) }
          it { expect(subject[:type_organization]).to eq(service.type_organisme) }
          it { expect(subject[:organization]).to eq(service.organisme) }
          it { expect(subject[:phone]).to eq(service.telephone) }
          it { expect(subject[:schedule]).to eq(service.horaires) }
          it { expect(subject[:address]).to eq(service.adresse) }
        end
      end
    end
  end
end
