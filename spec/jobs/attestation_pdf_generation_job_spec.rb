# frozen_string_literal: true

RSpec.describe AttestationPdfGenerationJob, type: :job do
  let(:procedure) { create(:procedure, :published) }
  let(:attestation_template) { create(:attestation_template, procedure: procedure, kind: :acceptation, state: :published) }
  let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

  before do
    attestation_template
  end

  describe '#perform' do
    context 'when attestation does not exist' do
      before do
        allow_any_instance_of(AttestationTemplate).to receive(:build_pdf).and_return('PDF_DATA')
      end

      it 'creates attestation and attaches PDF' do
        expect(dossier.attestation).to be_nil

        AttestationPdfGenerationJob.perform_now(dossier)

        expect(dossier.reload.attestation).to be_present
        expect(dossier.attestation.pdf.attached?).to be true
        expect(dossier.attestation.pdf.filename.to_s).to eq("attestation-dossier-#{dossier.id}.pdf")
        expect(dossier.attestation.pdf.content_type).to eq('application/pdf')
      end

      it 'calls build_pdf on the template' do
        template = dossier.procedure.attestation_acceptation_template
        expect(template).to receive(:build_pdf).with(dossier).and_return('PDF_DATA')

        AttestationPdfGenerationJob.perform_now(dossier)
      end

      context 'with attestation v1' do
        let(:attestation_template) do
          create(:attestation_template,
                 procedure: procedure,
                 kind: :acceptation,
                 state: :published,
                 title: 'Attestation dossier --numéro du dossier--',
                 version: 1)
        end

        before do
          allow_any_instance_of(AttestationTemplate).to receive(:build_pdf).and_return('PDF_DATA')
        end

        it 'creates the title with replaced tags' do
          AttestationPdfGenerationJob.perform_now(dossier)

          expect(dossier.reload.attestation.title).to eq("Attestation dossier #{dossier.id}")
        end
      end
    end

    context 'when attestation already exists' do
      before do
        create(:attestation, dossier: dossier)
      end

      it 'does not regenerate the PDF (idempotence)' do
        expect_any_instance_of(AttestationTemplate).not_to receive(:build_pdf)

        AttestationPdfGenerationJob.perform_now(dossier)
      end

      it 'does not create a new attestation' do
        expect {
          AttestationPdfGenerationJob.perform_now(dossier)
        }.not_to change { Attestation.count }
      end
    end

    context 'when build_pdf fails' do
      before do
        allow_any_instance_of(AttestationTemplate).to receive(:build_pdf).and_raise(StandardError, 'PDF generation failed')
      end

      it 'does not create attestation (atomicity)' do
        expect {
          AttestationPdfGenerationJob.perform_now(dossier)
        }.to raise_error(StandardError, 'PDF generation failed')

        expect(dossier.reload.attestation).to be_nil
      end
    end

    context 'when dossier is not found' do
      it 'discards the job without raising an error' do
        dossier.destroy

        expect {
          AttestationPdfGenerationJob.perform_now(dossier)
        }.not_to raise_error
      end
    end

    context 'when template is not configured' do
      let(:procedure_without_template) { create(:procedure, :published) }
      let(:dossier_without_template) { create(:dossier, :accepte, procedure: procedure_without_template) }

      it 'does not generate an attestation' do
        expect(dossier_without_template.attestation).to be_nil

        AttestationPdfGenerationJob.perform_now(dossier_without_template)

        expect(dossier_without_template.reload.attestation).to be_nil
      end
    end

    context 'for a refused dossier' do
      let(:attestation_template) { create(:attestation_template, :refus, procedure: procedure, kind: :refus, state: :published) }
      let(:dossier) { create(:dossier, :refuse, procedure: procedure) }

      before do
        allow_any_instance_of(AttestationTemplate).to receive(:build_pdf).and_return('PDF_DATA')
      end

      it 'uses the refusal template' do
        template = dossier.procedure.attestation_refus_template
        expect(template).to receive(:build_pdf).with(dossier).and_return('PDF_DATA')

        AttestationPdfGenerationJob.perform_now(dossier)

        expect(dossier.reload.attestation).to be_present
      end
    end
  end
end
