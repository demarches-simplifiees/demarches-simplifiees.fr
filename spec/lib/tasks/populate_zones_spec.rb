describe 'populate_zones' do
  let(:rake_task) { Rake::Task['zones:populate_zones'] }
  subject(:run_task) do
    rake_task.invoke
  end
  after(:each) do
    rake_task.reenable
  end

  it 'populates zones' do
    run_task
    expect(Zone.find_by(acronym: 'PM').label).to eq "Premier ministre"
  end
end
