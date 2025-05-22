RSpec.describe API::Public::V1::DossiersController, type: :controller do
  include Rails.application.routes.url_helpers

  describe '#create' do
    # Request prototype:
    # curl --request POST 'http://localhost:3000/api/public/v1/demarches/2/dossiers' \
    # --header 'Content-Type: application/json' \
    # --data '{"champ_Q2hhbXAtMjI=": "personne@fournisseur.fr"}'

    context 'when the request content type is json' do
      let(:params) { { id: procedure.id } }
      subject(:create_request) do
        request.headers["Content-Type"] = "application/json"
        post :create, params: params
      end

      shared_examples 'the procedure is found' do
        context 'when the dossier can be saved' do
          it { expect(create_request).to have_http_status(:created) }

          it { expect { create_request }.to change { Dossier.count }.by(1) }

          it "marks the created dossier as prefilled" do
            create_request
            expect(Dossier.last.prefilled).to eq(true)
          end

          it "creates the dossier without a user" do
            create_request
            expect(Dossier.last.user).to eq(nil)
          end

          it "responds with the brouillon dossier url and id" do
            create_request

            dossier = Dossier.last
            dossier_url = "http://test.host#{commencer_path(procedure.path, prefill_token: dossier.prefill_token)}"
            expect(response.parsed_body["dossier_url"]).to eq(dossier_url)
            expect(response.parsed_body["dossier_id"]).to eq(dossier.to_typed_id)
            expect(response.parsed_body["dossier_number"]).to eq(dossier.id)
          end

          context 'when prefill values are given' do
            let!(:type_de_champ_1) { create(:type_de_champ_text, procedure: procedure) }
            let(:value_1) { "any value" }

            let!(:type_de_champ_2) { create(:type_de_champ_textarea, procedure: procedure) }
            let(:value_2) { "another value" }

            let(:prenom_value) { "John" }
            let(:genre_value) { "M." }

            let(:params) {
              {
                id: procedure.id,
                "champ_#{type_de_champ_1.to_typed_id_for_query}" => value_1,
                "champ_#{type_de_champ_2.to_typed_id_for_query}" => value_2,
                "identite_prenom" => prenom_value,
                "identite_genre" => genre_value
              }
            }

            it "prefills the dossier's champs with the given values" do
              create_request

              dossier = Dossier.last
              expect(find_champ_by_stable_id(dossier, type_de_champ_1.stable_id).value).to eq(value_1)
              expect(find_champ_by_stable_id(dossier, type_de_champ_2.stable_id).value).to eq(value_2)
              expect(dossier.individual.prenom).to eq(prenom_value)
              expect(dossier.individual.gender).to eq(genre_value)
            end
          end
        end

        context 'when the dossier can not be saved' do
          before do
            allow_any_instance_of(Dossier).to receive(:save).and_return(false)
            allow_any_instance_of(Dossier).to receive(:errors).and_return(
              ActiveModel::Errors.new(Dossier.new).tap { |e| e.add(:base, "something went wrong") }
            )

            create_request
          end

          it { expect(response).to have_http_status(:bad_request) }

          it { expect(response).to have_failed_with("something went wrong") }
        end
      end

      shared_examples 'the procedure is not found' do
        before { create_request }

        it { expect(response).to have_http_status(:not_found) }

        it { expect(response).to have_failed_with("procedure #{procedure.id} is not found") }
      end

      context 'when the procedure is found' do
        context 'when the procedure is publiee' do
          it_behaves_like 'the procedure is found' do
            let(:procedure) { create(:procedure, :for_individual, :published) }
          end
        end

        context 'when the procedure is brouillon' do
          it_behaves_like 'the procedure is found' do
            let(:procedure) { create(:procedure, :for_individual, :draft) }
          end
        end

        context 'when the procedure is not publiee and not brouillon' do
          it_behaves_like 'the procedure is not found' do
            let(:procedure) { create(:procedure, :for_individual, :closed) }
          end
        end
      end

      context 'when the procedure is not found' do
        it_behaves_like 'the procedure is not found' do
          let(:procedure) { double(Procedure, id: -1) }
        end
      end
    end

    context 'when the request content type is not json' do
      subject(:create_request) do
        request.headers["Content-Type"] = "application/xhtml+xml"
        post :create, params: { id: 0 }
      end

      before { create_request }

      it { expect(response).to have_http_status(:bad_request) }

      it { expect(response).to have_failed_with("Content-Type should be json") }
    end
  end

  describe '#index' do
    let(:procedure) { dossier.procedure }
    let(:dossier) { create(:dossier, prefilled: true, user: nil) }
    let(:prefill_token) { dossier.prefill_token }
    let(:params) { { id: procedure.id, prefill_token: } }

    subject(:create_request) do
      request.headers["Content-Type"] = "application/json"
      get :index, params:
    end

    let(:body) { response.parsed_body.map(&:deep_symbolize_keys) }

    before { create_request }

    context 'not found' do
      let(:prefill_token) { 'invalid_token' }
      it 'should respond with and empty array' do
        expect(response).to have_http_status(:ok)
        expect(body).to eq([])
      end
    end

    context 'when dossier prefilled' do
      it 'should respond with dossier state' do
        expect(response).to have_http_status(:ok)
        expect(body.first[:state]).to eq('prefilled')
      end
    end

    context 'when dossier brouillon' do
      let(:dossier) { create(:dossier, prefilled: true) }
      it 'should respond with dossier state' do
        expect(response).to have_http_status(:ok)
        expect(body.first[:state]).to eq('brouillon')
      end
    end

    context 'when dossier en_construction' do
      let(:dossier) { create(:dossier, :en_construction, prefilled: true) }
      it 'should respond with dossier state' do
        expect(response).to have_http_status(:ok)
        expect(body.first[:state]).to eq('en_construction')
        expect(body.first[:submitted_at]).to eq(dossier.depose_at.iso8601)
      end
    end

    context 'with multiple tokens' do
      let(:dossier) { create(:dossier, prefilled: true, user: nil) }
      let(:other_dossier) { create(:dossier, prefilled: true, user: nil, procedure:) }
      let(:prefill_token) { [dossier.prefill_token, other_dossier.prefill_token] }

      it 'should respond with dossiers state' do
        expect(response).to have_http_status(:ok)
        expect(body.map { _1[:dossier_number] }).to match_array([dossier.id, other_dossier.id])
      end

      context 'comma separated tokens' do
        let(:prefill_token) { [dossier.prefill_token, other_dossier.prefill_token].join(',') }

        it 'should respond with dossiers state' do
          expect(response).to have_http_status(:ok)
          expect(body.map { _1[:dossier_number] }).to match_array([dossier.id, other_dossier.id])
        end
      end
    end
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs.find_by(stable_id:)
  end
end
