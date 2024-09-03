# frozen_string_literal: true

describe PingController, type: :controller do
  describe 'GET #index' do
    subject { get :index }

    it { expect(subject.status).to eq 200 }

    context 'when base is un-plug' do
      before do
        allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionTimeoutError)
      end

      it { expect { subject }.to raise_error(ActiveRecord::ConnectionTimeoutError) }
    end

    context 'when a maintenance file is present' do
      let(:filepath) { Rails.root.join('maintenance') }
      before do
        filepath.write("")
      end

      after do
        filepath.delete
      end

      it 'tells HAProxy that the app is in maintenance, but will be available again soon' do
        expect(subject.status).to eq 404
      end
    end
  end
end
