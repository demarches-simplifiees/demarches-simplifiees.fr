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
    expect(Zone.find_by(acronym: 'MTEI').labels.first.designated_on).to eq Date.parse('2022-05-20')
    expect(Zone.find_by(acronym: 'MTEI').labels.first.name).to eq "Ministère du Travail, du Plein emploi et de l'Insertion"
    expect(Zone.find_by(acronym: 'MTEI').labels.last.designated_on).to eq Date.parse('2020-07-06')
    expect(Zone.find_by(acronym: 'MTEI').labels.last.name).to eq "Ministère du Travail"
  end
end
