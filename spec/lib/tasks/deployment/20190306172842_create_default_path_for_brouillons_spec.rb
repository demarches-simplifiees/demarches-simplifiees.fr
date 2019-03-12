describe '20190306172842_create_default_path_for_brouillons.rake' do
  let(:rake_task) { Rake::Task['after_party:create_default_path_for_brouillons'] }

  let(:administrateur) { create(:administrateur) }
  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:procedure2) { create(:simple_procedure, administrateur: administrateur) }

  before do
    rake_task.invoke
    administrateur.reload
  end

  after { rake_task.reenable }

  it 'create a path for his brouillon procedure' do
    expect(administrateur.procedures.brouillon.count).to eq(1)
    expect(administrateur.procedures.brouillon.first.path).not_to eq(nil)
  end

  it 'does not change the path of his published procedure' do
    expect(administrateur.procedures.publiee.count).to eq(1)
    expect(administrateur.procedures.publiee.first.path).to eq(procedure2.path)
  end
end
