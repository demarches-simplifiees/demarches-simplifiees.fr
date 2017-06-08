describe AttestationTemplate, type: :model do
  describe 'validate' do
    let(:logo_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte }
    let(:signature_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte }
    let(:fake_logo) { double(AttestationTemplateImageUploader, file: double(size: logo_size)) }
    let(:fake_signature) { double(AttestationTemplateImageUploader, file: double(size: signature_size)) }
    let(:attestation_template) { AttestationTemplate.new }

    before do
      allow(attestation_template).to receive(:logo).and_return(fake_logo)
      allow(attestation_template).to receive(:signature).and_return(fake_signature)
      attestation_template.validate
    end

    subject { attestation_template.errors.details }

    context 'when no files are present' do
      let(:fake_logo) { nil }
      let(:fake_signature) { nil }

      it { is_expected.to match({}) }
    end

    context 'when the logo and the signature have the right size' do
      it { is_expected.to match({}) }
    end

    context 'when the logo and the signature are too heavy' do
      let(:logo_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte + 1 }
      let(:signature_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte + 1 }

      it do
        expected = {
          signature: [{ error: ' : vous ne pouvez pas charger une image de plus de 0,5 Mo' }],
          logo: [{ error: ' : vous ne pouvez pas charger une image de plus de 0,5 Mo' }]
        }

        is_expected.to match(expected)
      end
    end
  end

  describe 'dup' do
    before do
      @logo = File.open('spec/fixtures/white.png')
      @signature = File.open('spec/fixtures/black.png')
    end

    after do
      @logo.close
      @signature.close
      subject.destroy
    end

    let(:attestation_template) { AttestationTemplate.create(attributes) }
    subject { attestation_template.dup }

    context 'with an attestation without images' do
      let(:attributes) { { title: 't', body: 'b', footer: 'f', activated: true } }

      it { is_expected.to have_attributes(attributes) }
      it { is_expected.to have_attributes(id: nil) }
      it { expect(subject.logo.file).to be_nil }
    end

    context 'with an attestation with images' do
      let(:attributes) { { logo: @logo, signature: @signature } }

      it { expect(subject.logo.file.file).not_to eq(attestation_template.logo.file.file) }
      it { expect(subject.logo.file.read).to eq(attestation_template.logo.file.read) }

      it { expect(subject.signature.file.file).not_to eq(attestation_template.signature.file.file) }
      it { expect(subject.signature.file.read).to eq(attestation_template.signature.file.read) }
    end
  end
end
