describe AttestationTemplate, type: :model do
  # describe 'validate' do
  #   let(:logo_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte }
  #   let(:signature_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte }
  #   let(:fake_logo) { double(AttestationTemplateLogoUploader, file: double(size: logo_size)) }
  #   let(:fake_signature) { double(AttestationTemplateSignatureUploader, file: double(size: signature_size)) }
  #   let(:attestation_template) { AttestationTemplate.new }

  #   before do
  #     allow(attestation_template).to receive(:logo).and_return(fake_logo)
  #     allow(attestation_template).to receive(:signature).and_return(fake_signature)
  #     attestation_template.validate
  #   end

  #   subject { attestation_template.errors.details }

  #   context 'when no files are present' do
  #     let(:fake_logo) { nil }
  #     let(:fake_signature) { nil }

  #     it { is_expected.to match({}) }
  #   end

  #   context 'when the logo and the signature have the right size' do
  #     it { is_expected.to match({}) }
  #   end

  #   context 'when the logo and the signature are too heavy' do
  #     let(:logo_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte + 1 }
  #     let(:signature_size) { AttestationTemplate::FILE_MAX_SIZE_IN_MB.megabyte + 1 }

  #     it do
  #       expected = {
  #         signature: [{ error: ' : vous ne pouvez pas charger une image de plus de 0,5 Mo' }],
  #         logo: [{ error: ' : vous ne pouvez pas charger une image de plus de 0,5 Mo' }]
  #       }

  #       is_expected.to match(expected)
  #     end
  #   end
  # end

  describe 'validates footer length' do
    let(:attestation_template) { build(:attestation_template, footer: footer) }

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
    let(:attestation_template) { create(:attestation_template, attributes) }
    subject { attestation_template.dup }

    context 'with an attestation without images' do
      let(:attributes) { attributes_for(:attestation_template) }

      it { is_expected.to have_attributes(attributes) }
      it { is_expected.to have_attributes(id: nil) }
      it { expect(subject.logo.attached?).to be_falsey }
    end

    context 'with an attestation with images' do
      let(:attestation_template) { create(:attestation_template, :with_files) }

      it do
        expect(subject.logo.blob).not_to eq(attestation_template.logo.blob)
        expect(subject.logo.attached?).to be_truthy
      end

      it do
        expect(subject.signature.blob).not_to eq(attestation_template.signature.blob)
        expect(subject.signature.attached?).to be_truthy
      end
    end
  end

  describe 'invalidate attestation if images attachments are not valid' do
    subject { build(:attestation_template, :with_gif_files) }

    context 'with an attestation which has gif files' do
      it { is_expected.not_to be_valid }
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
    let(:etablissement) { create(:etablissement) }
    let(:types_de_champ) { [] }
    let(:types_de_champ_private) { [] }
    let!(:dossier) { create(:dossier, procedure: procedure, individual: individual, etablissement: etablissement) }
    let(:template_title) { 'title' }
    let(:template_body) { 'body' }
    let(:attestation_template) do
      build(:attestation_template, procedure: procedure,
        title: template_title,
        body: template_body,
        logo: @logo,
        signature: @signature)
    end

    before do
      Timecop.freeze(Time.zone.now)
    end

    after do
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

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ) do
        [
          create(:type_de_champ, libelle: 'libelleA'),
          create(:type_de_champ, libelle: 'libelleB')
        ]
      end

      context 'and the are used in the template title and body' do
        let(:template_title) { 'title --libelleA--' }
        let(:template_body) { 'body --libelleB--' }

        context 'and their value in the dossier are not nil' do
          before do
            dossier.champs
              .filter { |champ| champ.libelle == 'libelleA' }
              .first
              .update(value: 'libelle1')

            dossier.champs
              .filter { |champ| champ.libelle == 'libelleB' }
              .first
              .update(value: 'libelle2')
          end

          it do
            expect(view_args[:attestation][:title]).to eq('title libelle1')
            expect(view_args[:attestation][:body]).to eq('body libelle2')
            expect(attestation.title).to eq('title libelle1')
          end
        end
      end
    end
  end
end
