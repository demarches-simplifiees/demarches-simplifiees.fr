describe WebHookJob, type: :job do
  describe 'perform' do
    let(:procedure) { create(:procedure, web_hook_url:) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:web_hook_url) { "https://domaine.fr/callback_url" }
    let(:job) { WebHookJob.new(procedure.id, dossier.id, dossier.state, dossier.updated_at) }

    context 'with success on webhook' do
      it 'calls webhook' do
        stub_request(:post, web_hook_url).to_return(status: 200, body: "success")
        expect { job.perform_now }.not_to raise_error
      end
    end

    context 'with error on webhook' do
      it 'raises' do
        stub_request(:post, web_hook_url).to_return(status: 500, body: "error")
        expect { job.perform_now }.to raise_error
      end
    end
  end
end
