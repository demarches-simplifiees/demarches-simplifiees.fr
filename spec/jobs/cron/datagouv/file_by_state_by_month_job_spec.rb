# frozen_string_literal: true

RSpec.describe Cron::Datagouv::FileStateByMonthJob, type: :job do
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe '#perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::FileStateByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    let!(:procedure) { create(:procedure, :published, estimated_dossiers_count: 300, opendata: true) }
    let!(:dossier_brouillon) { create(:dossier, state: :brouillon, procedure:) }
    let!(:dossier_depose) { create(:dossier, state: :en_construction, procedure:) }
    let!(:dossier_en_instruction) { create(:dossier, state: :en_instruction, procedure:) }
    let!(:dossier_accepte) { create(:dossier, state: :accepte, procedure:) }
    let!(:dossier_refuse) { create(:dossier, state: :refuse, procedure:) }
    let!(:dossier_sans_suite) { create(:dossier, state: :sans_suite, procedure:) }

    subject { Cron::Datagouv::FileStateByMonthJob.new.data }

    context 'when all conditions are met' do
      it 'returns the correct data and structure' do
        expect(subject).to match_array(
          [[procedure.id, 1, 1, 1, 3]]
        )
      end
    end

    context 'when the procedure is not opendata' do
      before do
        procedure.update(opendata: false)
      end

      it 'does not include the procedure' do
        expect(subject).to be_empty
      end
    end

    context 'when the procedure has insufficient number of dossiers' do
      before do
        procedure.update(estimated_dossiers_count: 299)
      end

      it 'does not include the procedure' do
        expect(subject).to be_empty
      end
    end

    context 'when the procedure has several revisions' do
      before do
        procedure.publish_revision!
      end

      it 'only considers the published revision' do
        expect(subject).to be_empty
      end
    end
  end
end
