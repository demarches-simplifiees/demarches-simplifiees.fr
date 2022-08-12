describe 'administrateurs/procedures/edit.html.haml' do
  let(:logo) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
  let(:procedure) { create(:procedure, logo: logo, lien_site_web: 'http://some.website') }
  let(:populate_zones_task) { Rake::Task['zones:populate_zones'] }

  before do
    Flipper.enable(:zonage)
    populate_zones_task.invoke
  end

  after do
    populate_zones_task.reenable
  end

  context 'when procedure logo is present' do
    it 'display on the page' do
      assign(:procedure, procedure)
      render

      expect(rendered).to have_selector('.procedure-logos')
    end
  end

  context 'when procedure has never been published' do
    before { Timecop.freeze(now) }
    after { Timecop.return }

    let(:procedure) { create(:procedure, zone: Zone.find_by(acronym: 'MTEI')) }
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

    let(:procedure) { create(:procedure, zone: Zone.find_by(acronym: 'MTEI')) }
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
