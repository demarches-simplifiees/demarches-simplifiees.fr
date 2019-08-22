describe '2019_08_20_migrate_procedure_logo.rake' do
  let(:rake_task) { Rake::Task['2019_08_20_migrate_procedure_logo:run'] }

  let(:procedures) do
    [
      create(:procedure),
      create(:procedure, :with_legacy_logo),
      create(:procedure, :with_legacy_logo)
    ]
  end

  let(:run_task) do
    rake_task.invoke
    procedures.each(&:reload)
  end

  before do
    procedures.each do |procedure|
      if procedure.logo.present?
        stub_request(:get, procedure.logo_url)
          .to_return(status: 200, body: File.read(procedure.logo.path))
      end
    end
  end

  after do
    ENV['LIMIT'] = nil
    rake_task.reenable
  end

  it 'should migrate logo' do
    expect(procedures.map(&:logo_active_storage).map(&:attached?)).to eq([false, false, false])

    run_task

    expect(Procedure.where(logo: nil).count).to eq(1)
    expect(procedures.map(&:logo_active_storage).map(&:attached?)).to eq([false, true, true])
  end

  it 'should migrate logo within limit' do
    expect(procedures.map(&:logo_active_storage).map(&:attached?)).to eq([false, false, false])

    ENV['LIMIT'] = '1'
    run_task

    expect(Procedure.where(logo: nil).count).to eq(1)
    expect(procedures.map(&:logo_active_storage).map(&:attached?)).to eq([false, true, false])
  end

  context 'when a procedure is hidden' do
    let(:hidden_procedure) { create(:procedure, :hidden, :with_legacy_logo) }
    let(:procedures) { [hidden_procedure] }

    it 'should migrate logo' do
      run_task

      expect(hidden_procedure.logo_active_storage.attached?).to be true
    end
  end
end
