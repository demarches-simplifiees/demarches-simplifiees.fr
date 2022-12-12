RSpec.describe API::Public::V1::DossiersController, type: :controller do
  include Rails.application.routes.url_helpers

  describe '#create' do
    # Request prototype:
    # curl --request POST 'localhost:3000/api/public/v1/dossiers' \
    # --header 'Content-Type: application/json' \
    # --data '{"procedure_id": 2, "champ_Q2hhbXAtMg": "texte"}' | json_pp

    context 'when the procedure id is present' do
      let(:params) { { procedure_id: procedure.id } }
      subject(:create_request) do
        request.headers["Content-Type"] = "application/json"
        post :create, params: params
      end

      shared_examples 'the procedure is found' do
        context 'when the dossier can be saved' do
          it { expect(create_request).to have_http_status(:created) }

          it { expect { create_request }.to change { Dossier.count }.by(1) }

          it "responds with the brouillon dossier path" do
            create_request
            expect(JSON.parse(response.body)["dossier_url"]).to eq("http://test.host#{brouillon_dossier_path(Dossier.last)}")
          end

          context 'when prefill values are given' do
            let!(:type_de_champ_1) { create(:type_de_champ_text, procedure: procedure) }
            let(:value_1) { "any value" }

            let!(:type_de_champ_2) { create(:type_de_champ_textarea, procedure: procedure) }
            let(:value_2) { "another value" }

            let(:params) {
              {
                procedure_id: procedure.id,
                "champ_#{type_de_champ_1.to_typed_id}" => value_1,
                "champ_#{type_de_champ_2.to_typed_id}" => value_2
              }
            }

            it "prefills the dossier's champs with the given values" do
              create_request

              dossier = Dossier.last
              expect(find_champ_by_stable_id(dossier, type_de_champ_1.stable_id).value).to eq(value_1)
              expect(find_champ_by_stable_id(dossier, type_de_champ_2.stable_id).value).to eq(value_2)
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
          context 'when the procedure is opendata' do
            it_behaves_like 'the procedure is found' do
              let(:procedure) { create(:procedure, :published, opendata: true) }
            end
          end

          context 'when the procedure is not opendata' do
            it_behaves_like 'the procedure is not found' do
              let(:procedure) { create(:procedure, :published, opendata: false) }
            end
          end
        end

        context 'when the procedure is brouillon' do
          context 'when the procedure is opendata' do
            it_behaves_like 'the procedure is found' do
              let(:procedure) { create(:procedure, :draft, opendata: true) }
            end
          end

          context 'when the procedure is not opendata' do
            it_behaves_like 'the procedure is not found' do
              let(:procedure) { create(:procedure, :draft, opendata: false) }
            end
          end
        end

        context 'when the procedure is not publiee and not brouillon' do
          it_behaves_like 'the procedure is not found' do
            let(:procedure) { create(:procedure, :closed) }
          end
        end
      end

      context 'when the procedure is not found' do
        it_behaves_like 'the procedure is not found' do
          let(:procedure) { double(Procedure, id: -1) }
        end
      end
    end

    context 'when the procedure id is blank' do
      subject(:create_request) do
        request.headers["Content-Type"] = "application/json"
        post :create
      end

      before { create_request }

      it { expect(response).to have_http_status(:bad_request) }

      it { expect(response).to have_failed_with("procedure_id is missing") }
    end

    context 'when the request content type is not json' do
      subject(:create_request) do
        request.headers["Content-Type"] = "application/xhtml+xml"
        post :create, params: { procedure_id: 0 }
      end

      before { create_request }

      it { expect(response).to have_http_status(:bad_request) }

      it { expect(response).to have_failed_with("Content-Type should be json") }
    end
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs_public.joins(:type_de_champ).find_by(types_de_champ: { stable_id: stable_id })
  end
end
