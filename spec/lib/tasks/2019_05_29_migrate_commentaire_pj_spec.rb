describe '2019_05_29_migrate_commentaire_pj.rake' do
  let(:rake_task) { Rake::Task['2019_05_29_migrate_commentaire_pj:run'] }

  let!(:commentaires) do
    create(:commentaire)
    create(:commentaire, :with_file)
    create(:commentaire, :with_file)
  end

  before do
    Commentaire.all.each do |commentaire|
      if commentaire.file.present?
        stub_request(:get, commentaire.file_url)
          .to_return(status: 200, body: File.read(commentaire.file.path))
      end
    end
  end

  after do
    ENV['LIMIT'] = nil
    rake_task.reenable
  end

  it 'should migrate pj' do
    comment_updated_at = Commentaire.last.updated_at
    dossier_updated_at = Commentaire.last.dossier.updated_at
    expect(Commentaire.all.map(&:piece_jointe).map(&:attached?)).to eq([false, false, false])
    rake_task.invoke
    expect(Commentaire.where(file: nil).count).to eq(1)
    expect(Commentaire.all.map(&:piece_jointe).map(&:attached?)).to eq([false, true, true])
    expect(Commentaire.last.updated_at).to eq(comment_updated_at)
    expect(Commentaire.last.dossier.updated_at).to eq(dossier_updated_at)
  end

  it 'should migrate pj within limit' do
    expect(Commentaire.all.map(&:piece_jointe).map(&:attached?)).to eq([false, false, false])
    ENV['LIMIT'] = '1'
    rake_task.invoke
    expect(Commentaire.where(file: nil).count).to eq(1)
    expect(Commentaire.all.map(&:piece_jointe).map(&:attached?)).to eq([false, true, false])
  end
end
