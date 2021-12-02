describe '20211116140232_populate_zones' do
  let(:rake_task) { Rake::Task['after_party:populate_zones'] }
  subject(:run_task) do
    rake_task.invoke
  end

  it 'populates zones' do
    run_task
    expect(Zone.find_by(acronym: 'SPM').label).to eq "Premier ministre"
  end
end
