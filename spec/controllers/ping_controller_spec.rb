describe PingController, type: :controller do
  describe 'GET #index' do
    subject { get :index }

    it { expect(subject.status).to eq 200 }

    context 'when base is un-plug' do
      before do
        allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      end

      it { expect(subject.status).to eq 500 }
    end

    context 'when a maintenance file is present' do
      before do
        allow(File).to receive(:file?).and_return(true)
      end

      it 'tells HAProxy that the app is in maintenance, but will be available again soon' do
        expect(subject.status).to eq 404
      end
    end
  end
end
