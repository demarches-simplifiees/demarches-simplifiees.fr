RSpec.describe Cron::Datagouv::ChampFilledByMonthJob, type: :job do
  let!(:user) { create(:user, created_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe '#perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::ChampFilledByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    let!(:procedure) { create(:procedure, :published, estimated_dossiers_count: 20, opendata: true) }
    let!(:type_de_champ) { create(:type_de_champ_text, libelle: 'libelle', procedure:) }
    let!(:dossier) { create(:dossier, depose_at: 1.month.ago, procedure:) }
    let!(:champ) { dossier.champs.first }

    subject { Cron::Datagouv::ChampFilledByMonthJob.new.data }

    context 'when all conditions are met' do
      before do
        champ.update(value: "filled")
      end

      it 'returns the correct data and structure' do
        expect(subject).to match_array(
          [[procedure.id, type_de_champ.to_typed_id, "text", "libelle", 1]]
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
        procedure.update(estimated_dossiers_count: 19)
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

    context 'when the champ is empty' do
      before do
        champ.update(value: nil)
      end

      it 'does not count champ' do
        expect(subject).to match_array(
          [[procedure.id, type_de_champ.to_typed_id, "text", "libelle", 0]]
        )
      end
    end

    context 'when the type_de_champ is private' do
      before do
        type_de_champ.update(private: true)
      end

      it 'does not count type_de_champ' do
        expect(subject).to be_empty
      end
    end
  end
end
