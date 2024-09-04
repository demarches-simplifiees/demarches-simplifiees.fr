# frozen_string_literal: true

describe ExportJob do
  let(:procedure) { create(:procedure, instructeurs: [user_profile]) }
  let(:user_profile) { create(:instructeur) }
  let(:time_span_type) { :everything }
  let(:status) { :tous }
  let(:key) { '123' }
  let(:export) do
    create(:export, format:,
                    time_span_type:,
                    key:,
                    user_profile:,
                    groupe_instructeurs: procedure.groupe_instructeurs)
  end

  subject do
    ExportJob.perform_now(export)
  end
  before do
    allow_any_instance_of(ArchiveUploader).to receive(:syscall_to_custom_uploader).and_return(true)
  end

  context 'zip' do
    let(:format) { :zip }

    it 'does not try to identify file' do
      expect { subject }.not_to raise_error
    end
  end
end
