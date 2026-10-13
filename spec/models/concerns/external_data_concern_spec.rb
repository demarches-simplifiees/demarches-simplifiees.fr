# frozen_string_literal: true

RSpec.describe ExternalDataConcern do
  include Dry::Monads[:result]

  describe '#save_external_error' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first }
    context "add execption to the log" do
      it do
        champ.send(:save_external_error, double(inspect: 'PAN'), 404)
        expect { champ.reload }.not_to raise_error
      end
    end
  end

  describe '#external_data_not_found?' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first }

    before do
      champ.external_state = external_state
      champ.fetch_external_data_exceptions = exceptions
    end

    context 'in external_error with a 404 exception' do
      let(:external_state) { 'external_error' }
      let(:exceptions) { [ExternalDataException.new(error: 'NotFound', code: 404)] }

      it { expect(champ).to be_external_data_not_found }
    end

    context 'in external_error with a non-404 exception' do
      let(:external_state) { 'external_error' }
      let(:exceptions) { [ExternalDataException.new(error: 'Boom', code: 500)] }

      it { expect(champ).not_to be_external_data_not_found }
    end

    context 'in external_error without recorded exceptions' do
      let(:external_state) { 'external_error' }
      let(:exceptions) { nil }

      it { expect(champ).not_to be_external_data_not_found }
    end

    context 'when not in error' do
      let(:external_state) { 'fetched' }
      let(:exceptions) { [] }

      it { expect(champ).not_to be_external_data_not_found }
    end
  end

  describe '#update_external_data!' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }
    let(:champ) { dossier.champ_data.first }
    let(:before_fetch) { 1.week.ago.change(usec: 0) }
    let(:data) { { 'title' => 'Fondation SFR' } }

    before do
      dossier.update_columns(depose_at: before_fetch, last_champ_updated_at: before_fetch)
      champ.update_columns(external_state: 'fetching', updated_at: before_fetch, value_updated_at: before_fetch)
    end

    context 'when the data lands after the deposit' do
      it 'dates the arrival on the champ and on the dossier, like an edit' do
        champ.send(:handle_result, Success(data:))

        champ.reload
        expect(champ.read_attribute(:value_updated_at)).to be > before_fetch
        expect(dossier.reload.last_champ_updated_at).to eq(champ.read_attribute(:value_updated_at))
      end
    end

    context 'when the fetch lands the same data again (retry, idempotent refetch)' do
      before { champ.update_columns(data:) }

      it 'does not move the timestamps' do
        champ.send(:handle_result, Success(data:))

        expect(champ.reload.read_attribute(:value_updated_at)).to eq(before_fetch)
        expect(dossier.reload.last_champ_updated_at).to eq(before_fetch)
      end
    end

    context 'when the champ sits on a buffer stream' do
      before { champ.update_columns(stream: Dossier::USER_BUFFER_STREAM) }

      it 'leaves the stamp to the buffer merge' do
        champ.send(:handle_result, Success(data:))

        expect(champ.reload.read_attribute(:value_updated_at)).to eq(before_fetch)
        expect(dossier.reload.last_champ_updated_at).to eq(before_fetch)
      end
    end

    context 'when the fetch fails' do
      it 'does not move the timestamps on a retryable failure' do
        failure = Failure(retryable: true, error: StandardError.new('degraded'), code: 503)

        expect { champ.send(:handle_result, failure) }.to raise_error(RetryableFetchError)
        expect(champ.reload.read_attribute(:value_updated_at)).to eq(before_fetch)
        expect(dossier.reload.last_champ_updated_at).to eq(before_fetch)
      end

      it 'does not move the timestamps on a final failure' do
        allow(Sentry).to receive(:capture_exception)
        failure = Failure(retryable: false, error: StandardError.new('nop'), code: 500)

        champ.send(:handle_result, failure)

        expect(champ).to be_external_error
        expect(champ.reload.read_attribute(:value_updated_at)).to eq(before_fetch)
        expect(dossier.reload.last_champ_updated_at).to eq(before_fetch)
      end
    end
  end

  describe 'the state machine' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first }

    describe 'initial state' do
      it { expect(champ).to be_idle }
    end

    describe 'fetch_later' do
      let(:ready_for_external_call?) { true }

      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(ready_for_external_call?)
        allow(champ).to receive(:fetch_external_data_later)
      end

      context 'without args' do
        subject { champ.fetch_later!; champ }

        it do
          is_expected.to be_waiting_for_job
          expect(champ).to have_received(:fetch_external_data_later)
        end

        context 'when not ready for external call' do
          let(:ready_for_external_call?) { false }

          it 'does not change the state' do
            expect(champ.may_fetch_later?).to be_falsey
            expect { subject }.to raise_error(AASM::InvalidTransition)
          end
        end
      end

      context 'with a wait arg' do
        subject { champ.fetch_later!(wait: 20); champ }

        it do
          is_expected.to be_waiting_for_job
          expect(champ).to have_received(:fetch_external_data_later).with(wait: 20)
        end
      end
    end

    describe 'fetch' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!
        allow(champ).to receive(:fetch_and_handle_result)
      end

      subject { champ.fetch!; champ }

      it do
        is_expected.to be_fetching
        expect(champ).to have_received(:fetch_and_handle_result)
      end
    end

    describe 'dossier timestamps' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!
      end

      it 'a state transition alone does not date the dossier' do
        allow(champ).to receive(:fetch_and_handle_result)

        expect { champ.fetch! }.not_to change { dossier.reload.updated_at }
      end

      it 'the data a fetch brings does' do
        allow(champ).to receive(:fetch_external_data).and_return(Success(value_json: { 'title' => 'Fondation' }))

        expect { champ.fetch! }.to change { dossier.reload.updated_at }
      end
    end

    describe 'fetch a success, now is fetched state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        allow(champ).to receive(:fetch_external_data).and_return(Success('some data'))
        allow(champ).to receive(:update_external_data!)
        champ.fetch!
      end

      it { expect(champ).to be_fetched }
    end

    describe 'fetch a non retryable failure, now is external_error state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        failure = Failure(retryable: false, error: Exception.new('nop'), code:)
        allow(champ).to receive(:fetch_external_data).and_return(failure)
        allow(Sentry).to receive(:capture_exception)
        champ.fetch!
      end

      context 'when code is 404' do
        let(:code) { 404 }

        it do
          expect(champ).to be_external_error
          expect(Sentry).not_to have_received(:capture_exception)
        end
      end

      context 'when code is 500' do
        let(:code) { 500 }

        it { expect(Sentry).to have_received(:capture_exception) }
      end

      context 'when code is nil' do
        let(:code) { nil }

        it { expect(champ).to be_external_error }
      end
    end

    describe 'fetch a retryable failure, now is back in waiting_for_job state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        failure = Failure(retryable: true, error: Exception.new('nop'), code: 404)
        allow(champ).to receive(:fetch_external_data).and_return(failure)
      end

      subject { champ.fetch!; champ }

      it do
        expect { subject }.to raise_error(RetryableFetchError)
        expect(champ.reload).to be_waiting_for_job
      end
    end

    describe 'fetch a degraded failure, now is degraded state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.update_columns(fetch_external_data_exceptions: [ExternalDataException.new(error: 'previous', code: 502)])
        champ.fetch_later!

        failure = Failure(degraded: true, error: Exception.new('nop'), code: 503)
        allow(champ).to receive(:fetch_external_data).and_return(failure)
        champ.fetch!
      end

      it 'records the last error only: the cron replays it every two hours' do
        expect(champ.reload).to be_degraded
        expect(champ.fetch_external_data_exceptions.map(&:code)).to eq([503])
      end

      it { expect(champ).to be_external_data_settled }
    end

    describe 'leaving the degraded state' do
      before { champ.update_column(:external_state, 'degraded') }

      it 'can be reset' do
        champ.reset_external_data!

        expect(champ).to be_idle
      end
    end

    describe 'waiting for the fix' do
      before do
        champ.update_column(:external_state, 'waiting_for_fix')
        allow(champ).to receive(:fetch_and_handle_result)
      end

      it 'still reads as degraded' do
        expect(champ).to be_awaiting_fix
        expect(champ).to be_external_data_settled
      end

      it 'is fetched when the job runs' do
        champ.fetch!

        expect(champ).to be_fetching
      end

      it 'can be reset' do
        champ.reset_external_data!

        expect(champ).to be_idle
      end
    end

    describe 'fix_degraded' do
      before do
        champ.update_column(:external_state, 'degraded')
        allow(champ).to receive(:fetch_external_data_later)
      end

      it 'goes back in the queue, with the given wait, without blocking the user' do
        champ.fix_degraded!(wait: 20)

        expect(champ).to be_waiting_for_fix
        expect(champ).not_to be_pending
        expect(champ).to have_received(:fetch_external_data_later).with(wait: 20)
      end

      it 'does not widen fetch_later, whose guard is used elsewhere' do
        expect(champ.may_fetch_later?).to be_falsey
      end
    end

    describe 'reset_external_data' do
      context 'from idle' do
        before { champ.reset_external_data! }

        it { expect(champ).to be_idle }
      end
      context 'from waiting_for_job' do
        before do
          allow(champ).to receive(:ready_for_external_call?).and_return(true)
          champ.fetch_later!

          allow(champ).to receive(:after_reset_external_data)
          champ.reset_external_data!
        end

        it do
          expect(champ).to be_idle
          expect(champ).to have_received(:after_reset_external_data)
        end
      end
    end
  end

  describe '#fetch_now!' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :siret }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champ_data.first.tap { it.update_columns(external_id: '30613890001294', value: '30613890001294') } }

    before do
      allow(champ).to receive(:fetch_external_data)
        .and_return(Failure(degraded: true, error: StandardError.new('API Entreprise: unavailable'), code: 503))
    end

    it 'fetches from idle in the current request, without enqueuing a job' do
      expect { champ.fetch_now! }.not_to have_enqueued_job(FetchExternalDataJob)
      expect(champ.reload).to be_degraded
    end
  end
end
