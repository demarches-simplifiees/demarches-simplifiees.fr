describe 'APIRechercheEntreprisesService' do
  include Dry::Monads[:result]
  OK = Data.define(:body, :response)

  def load_json(file_name)
    Rails.root.join("spec/fixtures/files/api_recherche_entreprises/#{file_name}.json")
      .then { File.read(_1) }
      .then { JSON.parse(_1).with_indifferent_access }
  end

  let(:col_ter_json) { load_json('col_ter_20006541500016') }
  let(:dinum_json) { load_json('dinum_13002526500013') }

  describe '.collectivite_territoriale' do
    let(:client_response) { Success(OK[json_response, '']) }

    subject { APIRechercheEntreprisesService.collectivite_territoriale?(siret:) }

    before { expect_any_instance_of(API::Client).to receive(:call).and_return(client_response) }

    context 'when the api returns some results' do
      let(:json_response) { col_ter_json }

      context 'and the siret match' do
        context 'and the structure is a collectivite territoriale' do
          let(:siret) { '20006541500016' }

          it { is_expected.to be true }
        end

        context 'and the structure is not a collectivite territoriale' do
          let(:json_response) { dinum_json }
          let(:siret) { '13002526500013' }

          it { is_expected.to be false }
        end
      end

      context 'and the siret does not match' do
        let(:siret) { '20006541500666' }

        it { is_expected.to be false }
      end
    end

    context 'when the api returns no result' do
      let(:json_response) { { results: [] } }
      let(:siret) { '20006541500016' }

      it { is_expected.to be false }
    end

    context 'when the api returns an error' do
      let(:client_response) { Failure() }
      let(:siret) { '20006541500016' }

      it { is_expected.to be false }
    end
  end
end
