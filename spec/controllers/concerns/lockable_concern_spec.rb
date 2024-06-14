describe LockableConcern, type: :controller do
  controller(ApplicationController) do
    include LockableConcern

    def test_action
      lock_action(params.fetch(:lock_key)) do
        render plain: 'Action completed'
      end
    end
  end

  before do
    routes.draw { get 'test_action/:lock_key' => 'anonymous#test_action' }
  end

  describe '#lock_action' do
    # randomize key to avoid collision on concurrent tests
    let(:lock_key) { "test_lock_#{SecureRandom.uuid}" }
    subject { get :test_action, params: { lock_key: } }

    context 'when there is no concurrent request' do
      it 'completes the action' do
        expect(subject).to have_http_status(:ok)
      end
    end

    context 'when there are concurrent requests' do
      it 'aborts the second request' do
        # Simulating the first request acquiring the lock
        Kredis.flag(lock_key).mark(expires_in: 3.seconds)

        # Making the second request
        expect(subject).to have_http_status(:locked)
      end
    end

    context 'when the lock expires' do
      it 'allows another request after expiration' do
        Kredis.flag(lock_key).mark(expires_in: 0.001.seconds)
        sleep 0.002

        expect(subject).to have_http_status(:ok)
      end
    end
  end
end
