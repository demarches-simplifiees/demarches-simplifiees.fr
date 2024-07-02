# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChampFetchExternalDataJob, type: :job do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :communes }] }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }

  let(:external_id) { "an ID" }
  let(:champ_external_id) { "an ID" }
  let(:data) { nil }
  let(:fetched_data) { nil }
  let(:reason) { StandardError.new("error") }

  subject(:perform_job) { described_class.perform_now(champ, external_id) }

  include Dry::Monads[:result]

  before do
    champ.update_columns(external_id: champ_external_id, data:)
    allow(champ).to receive(:fetch_external_data).and_return(fetched_data)
    allow(champ).to receive(:update_with_external_data!)
    allow(champ).to receive(:log_fetch_external_data_exception)
  end

  shared_examples "a champ non-updater" do
    it 'does not update the champ' do
      perform_job
      expect(champ).not_to have_received(:update_with_external_data!)
    end
  end

  context 'when external_id matches the champ external_id and the champ data is nil' do
    it 'fetches external data' do
      perform_job
      expect(champ).to have_received(:fetch_external_data)
    end

    context 'when the fetched data is present' do
      let(:fetched_data) { "data" }

      it 'updates the champ' do
        perform_job
        expect(champ).to have_received(:update_with_external_data!).with(data: fetched_data)
      end
    end

    context 'when the fetched data is a result' do
      context 'success' do
        let(:fetched_data) { Success("data") }

        it 'updates the champ' do
          perform_job
          expect(champ).to have_received(:update_with_external_data!).with(data: fetched_data.value!)
        end
      end

      context 'retryable failure' do
        let(:fetched_data) { Failure(API::Client::Error[:http, 400, true, reason]) }

        it 'saves exception and raise' do
          expect { perform_job }.to raise_error StandardError
          expect(champ).to have_received(:log_fetch_external_data_exception).with(reason)
        end
      end

      context 'fatal failure' do
        let(:fetched_data) { Failure(API::Client::Error[:http, 400, false, reason]) }

        it 'saves exception' do
          perform_job
          expect(champ).to have_received(:log_fetch_external_data_exception).with(reason)
        end
      end
    end

    context 'when the fetched data is blank' do
      it_behaves_like "a champ non-updater"
    end
  end

  context 'when external_id does not match the champ external_id' do
    let(:champ_external_id) { "something else" }
    it_behaves_like "a champ non-updater"
  end

  context 'when the champ data is present' do
    let(:data) { "present" }
    it_behaves_like "a champ non-updater"
  end
end
