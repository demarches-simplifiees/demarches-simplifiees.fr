describe Recovery::Importer do
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'recovery', 'export.dump') }
  let(:importer) { Recovery::Importer.new(file_path:) }
  subject { importer.load }
  context 'loaded_data' do
    let(:loaded_dossiers) { importer.dossiers}

    it 'contains user' do
      expect(loaded_dossiers.first.user).to be_an_instance_of(User)
    end
  end

  it 're-import dossiers from .dump' do
    expect{ subject }.to change { Dossier.count }.by(importer.dossiers.size)
  end
end
