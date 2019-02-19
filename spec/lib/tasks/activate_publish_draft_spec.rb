require 'spec_helper'

describe 'activate_publish_draft#clean' do
  let(:rake_task) { Rake::Task['support:activate_publish_draft'] }

  let(:administrateur) { create(:administrateur) }
  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:procedure2) { create(:simple_procedure, administrateur: administrateur) }

  before do
    ENV['START_WITH'] = administrateur.email
    rake_task.invoke
    administrateur.reload
  end

  after { rake_task.reenable }

  it 'activate feature for administrateur' do
    expect(administrateur.features["publish_draft"]).to eq(true)
  end

  it 'create a path for his brouillon procedure' do
    expect(administrateur.procedures.brouillon.count).to eq(1)
    expect(administrateur.procedures.brouillon.first.path).not_to eq(nil)
  end

  it 'does not change the path of his published procedure' do
    expect(administrateur.procedures.publiee.count).to eq(1)
    expect(administrateur.procedures.publiee.first.path).to eq(procedure2.path)
  end
end
