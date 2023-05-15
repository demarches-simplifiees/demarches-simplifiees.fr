describe Recovery::Exporter do
  let(:dossier_ids) { [create(:dossier, :with_individual).id, create(:dossier, :with_individual).id] }
  let(:fp) { Rails.root.join('spec', 'fixtures', 'recovery', 'export.dump') }
  subject { Recovery::Exporter.new(dossier_ids:, file_path: fp).dump }

  def cleanup_export_file
    # if File.exist?(fp)
    # FileUtils.rm(fp)
    # end
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

  context 'exported' do
    before { subject }
    let(:exported_dossiers) { Marshal.load(File.read(fp)) }

    it 'contains as much as dossiers as input' do
      expect(exported_dossiers.size).to eq(dossier_ids.size)
    end

    it 'contains input dossier ids' do
      expect(exported_dossiers.map(&:id)).to match_array(dossier_ids)
    end

    it 'contains procedure dossier ids' do
      expect(exported_dossiers.first.procedure).to be_an_instance_of(Procedure)
    end

    it 'contains dossier.revision ids' do
      expect(exported_dossiers.first.revision).to be_an_instance_of(ProcedureRevision)
    end

    it 'contains dossier.user' do
      expect(exported_dossiers.first.user).to be_an_instance_of(User)
    end
  end
end
