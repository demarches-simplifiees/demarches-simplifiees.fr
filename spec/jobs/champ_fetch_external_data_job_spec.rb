# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChampFetchExternalDataJob, type: :job do
  include Dry::Monads[:result]

  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :rnf }]) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:external_id) { champ.external_id }

  describe 'perform' do
    before do
      allow(champ).to receive(:fetch!)
      described_class.new.perform(champ, external_id)
    end

    context 'when external_id matches the champ external_id' do
      it { expect(champ).to have_received(:fetch!) }
    end

    context 'when external_id does not match the champ external_id' do
      let(:external_id) { "something else" }

      it { expect(champ).not_to have_received(:fetch!) }
    end
  end

  describe 'error handling and backoff strategy' do
    before { expect_any_instance_of(Champ).to receive(:fetch!).and_raise(error) }

    context 'when a retryable error occurs' do
      let(:error) { Excon::Error::InternalServerError.new('Retryable error') }

      it 'retries 5 times and the final state is external_error' do
        assert_performed_jobs 6 do
          described_class.perform_later(champ, external_id) rescue Excon::Error::InternalServerError
        end
        expect(champ.reload).to be_external_error
      end
    end
  end
end
