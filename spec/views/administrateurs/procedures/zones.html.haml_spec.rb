describe 'administrateurs/procedures/zones' do
  let(:administrateur) { create(:administrateur) }
  let(:procedure) { create(:procedure) }
  let(:populate_zones_task) { Rake::Task['after_party:populate_zones_with_tchap_hs'] }

  before do
    Rails.application.config.ds_zonage_enabled = true
    populate_zones_task.invoke
    allow(view).to receive(:current_administrateur).and_return(administrateur)
  end

  after do
    populate_zones_task.reenable
  end

  context 'when procedure has never been published' do
    before { Timecop.freeze(now) }
    after { Timecop.return }

    let(:procedure) { create(:procedure, zones: [Zone.find_by(acronym: 'MTEI')]) }
    let(:now) { Time.zone.parse('18/05/2022') }

    it 'displays zones with label available at the creation date' do
      assign(:procedure, procedure)
      render

      expect(rendered).to have_content("Ministère du Travail")
      expect(rendered).not_to have_content("Ministère du Travail, du Plein emploi et de l'Insertion")
    end
  end

  context 'when procedure has been published' do
    before { Timecop.freeze(now) }
    after { Timecop.return }

    let(:procedure) { create(:procedure, zones: [Zone.find_by(acronym: 'MTEI')]) }
    let(:now) { Time.zone.parse('18/05/2022') }

    it 'displays zones with label available at the creation date' do
      Timecop.freeze(Time.zone.parse('22/05/2022')) do
        procedure.publish!
      end

      assign(:procedure, procedure)
      render

      expect(rendered).to have_content("Ministère du Travail, du Plein emploi et de l'Insertion")
    end
  end
end
