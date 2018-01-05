describe AttestationTemplate, type: :model do
  describe 'validate' do
    let(:logo_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte }
    let(:signature_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte }
    let(:fake_logo) { double(AttestationTemplateLogoUploader, file: double(size: logo_size)) }
    let(:fake_signature) { double(AttestationTemplateSignatureUploader, file: double(size: signature_size)) }
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

  describe 'validates footer length' do
    let(:attestation_template) { AttestationTemplate.new(footer: footer) }

    subject do
      attestation_template.validate
      attestation_template.errors.details
    end

    context 'when the footer is too long' do
      let(:footer) { 'a' * 191 }

      it { is_expected.to match({ footer: [{ error: :too_long, count: 190 }] }) }
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

  describe 'attestation_for' do
    let(:procedure) do
      create(:procedure,
        types_de_champ: types_de_champ,
        types_de_champ_private: types_de_champ_private,
        for_individual: for_individual)
    end
    let(:for_individual) { false }
    let(:individual) { nil }
    let(:etablissement) { nil }
    let(:entreprise) { create(:entreprise, etablissement: etablissement) }
    let(:types_de_champ) { [] }
    let(:types_de_champ_private) { [] }
    let!(:dossier) { create(:dossier, procedure: procedure, individual: individual, entreprise: entreprise) }
    let(:template_title) { 'title' }
    let(:template_body) { 'body' }
    let(:attestation_template) do
      AttestationTemplate.new(procedure: procedure,
        title: template_title,
        body: template_body,
        logo: @logo,
        signature: @signature)
    end

    before do
      @logo = File.open('spec/fixtures/white.png')
      @signature = File.open('spec/fixtures/black.png')
      Timecop.freeze(Time.now)
    end

    after do
      @logo.close
      @signature.close
      Timecop.return
    end

    let(:view_args) do
      original_new = ActionView::Base.method(:new)
      arguments = nil

      allow(ActionView::Base).to receive(:new) do |paths, args|
        arguments = args
        original_new.call(paths, args)
      end

      attestation_template.attestation_for(dossier)

      arguments
    end

    let(:attestation) { attestation_template.attestation_for(dossier) }

    it 'provides a pseudo file' do
      expect(attestation.pdf.file).to exist
      expect(attestation.pdf.filename).to start_with('attestation')
    end

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ) do
        [create(:type_de_champ_public, libelle: 'libelleA'),
         create(:type_de_champ_public, libelle: 'libelleB')]
      end

      context 'and the are used in the template title and body' do
        let(:template_title) { 'title --libelleA--' }
        let(:template_body) { 'body --libelleB--' }

        context 'and their value in the dossier are not nil' do
          before do
            dossier.champs
              .select { |champ| champ.libelle == 'libelleA' }
              .first
              .update_attributes(value: 'libelle1')

            dossier.champs
              .select { |champ| champ.libelle == 'libelleB' }
              .first
              .update_attributes(value: 'libelle2')
          end

          it { expect(view_args[:title]).to eq('title libelle1') }
          it { expect(view_args[:body]).to eq('body libelle2') }
          it { expect(attestation.title).to eq('title libelle1') }
        end
      end
    end
  end
end
