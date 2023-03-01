# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChampFetchExternalDataJob, type: :job do
  let(:champ) { Struct.new(:external_id, :data).new(champ_external_id, data) }
  let(:external_id) { "an ID" }
  let(:champ_external_id) { "an ID" }
  let(:data) { nil }
  let(:fetched_data) { nil }

  subject(:perform_job) { described_class.perform_now(champ, external_id) }

  before do
    allow(champ).to receive(:fetch_external_data).and_return(fetched_data)
    allow(champ).to receive(:update_with_external_data!)
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
