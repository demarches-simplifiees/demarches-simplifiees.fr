describe '2019_08_22_migrate_attestation_files.rake' do
  let(:rake_task) { Rake::Task["2019_08_22_migrate_attestation_files:#{sub_task}"] }

  let(:run_task) do
    rake_task.invoke
    models.each(&:reload)
  end

  after do
    ENV['LIMIT'] = nil
    rake_task.reenable
  end

  context 'attestation' do
    let(:models) do
      [
        create(:attestation, created_at: 3.days.ago),
        create(:attestation, :with_legacy_pdf, created_at: 2.days.ago),
        create(:attestation, :with_legacy_pdf, created_at: 1.day.ago)
      ]
    end

    before do
      first_attestation = models[0]
      expect(first_attestation.pdf.present?).to be_falsey
      expect(first_attestation.read_attribute(:pdf)).to be_nil

      models.each do |attestation|
        if attestation.pdf.present?
          stub_request(:get, attestation.pdf_url)
            .to_return(status: 200, body: File.read(attestation.pdf.path))
        end
      end
    end

    context 'pdf' do
      let(:sub_task) { 'migrate_attestation_pdf' }

      it 'should migrate pdf' do
        expect(models.map(&:pdf_active_storage).map(&:attached?)).to eq([false, false, false])

        run_task

        expect(Attestation.where(pdf: nil).count).to eq(1)
        expect(models.map(&:pdf_active_storage).map(&:attached?)).to eq([false, true, true])
      end

      it 'should migrate pdf within limit' do
        expect(models.map(&:pdf_active_storage).map(&:attached?)).to eq([false, false, false])

        ENV['LIMIT'] = '1'
        run_task

        expect(Attestation.where(pdf: nil).count).to eq(1)
        expect(models.map(&:pdf_active_storage).map(&:attached?)).to eq([false, true, false])
      end
    end
  end

  context 'attestation_templates' do
    let(:models) do
      [
        create(:attestation_template),
        create(:attestation_template, :with_legacy_files),
        create(:attestation_template, :with_legacy_files)
      ]
    end

    before do
      models.each do |attestation_template|
        if attestation_template.logo.present?
          stub_request(:get, attestation_template.logo_url)
            .to_return(status: 200, body: File.read(attestation_template.logo.path))
        end
        if attestation_template.signature.present?
          stub_request(:get, attestation_template.signature_url)
            .to_return(status: 200, body: File.read(attestation_template.signature.path))
        end
      end
    end

    context 'logo' do
      let(:sub_task) { 'migrate_attestation_template_logo' }

      it 'should migrate logo' do
        expect(models.map(&:logo_active_storage).map(&:attached?)).to eq([false, false, false])

        run_task

        expect(AttestationTemplate.where(logo: nil).count).to eq(1)
        expect(models.map(&:logo_active_storage).map(&:attached?)).to eq([false, true, true])
      end

      it 'should migrate logo within limit' do
        expect(models.map(&:logo_active_storage).map(&:attached?)).to eq([false, false, false])

        ENV['LIMIT'] = '1'
        run_task

        expect(AttestationTemplate.where(logo: nil).count).to eq(1)
        expect(models.map(&:logo_active_storage).map(&:attached?)).to eq([false, true, false])
      end
    end

    context 'signature' do
      let(:sub_task) { 'migrate_attestation_template_signature' }

      it 'should migrate signature' do
        expect(models.map(&:signature_active_storage).map(&:attached?)).to eq([false, false, false])

        run_task

        expect(AttestationTemplate.where(signature: nil).count).to eq(1)
        expect(models.map(&:signature_active_storage).map(&:attached?)).to eq([false, true, true])
      end

      it 'should migrate signature within limit' do
        expect(models.map(&:signature_active_storage).map(&:attached?)).to eq([false, false, false])

        ENV['LIMIT'] = '1'
        run_task

        expect(AttestationTemplate.where(signature: nil).count).to eq(1)
        expect(models.map(&:signature_active_storage).map(&:attached?)).to eq([false, true, false])
      end
    end
  end
end
