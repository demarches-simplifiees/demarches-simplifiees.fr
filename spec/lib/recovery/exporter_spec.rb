# frozen_string_literal: true

describe Recovery::Exporter do
  let(:dossier_ids) { [create(:dossier, :with_individual).id, create(:dossier, :with_individual).id] }
  let(:fp) { Rails.root.join('spec', 'fixtures', 'export.dump') }
  subject { Recovery::Exporter.new(dossier_ids:, file_path: fp).dump }

  def cleanup_export_file
    if File.exist?(fp)
      FileUtils.rm(fp)
    end
  end

  before { cleanup_export_file }
  after { cleanup_export_file }

  it 'exports dossiers to .dump' do
    expect { subject }.not_to raise_error
  end

  it 'exports dossiers local file .dump' do
    expect { subject }.to change { File.exist?(fp) }
      .from(false).to(true)
  end
end
