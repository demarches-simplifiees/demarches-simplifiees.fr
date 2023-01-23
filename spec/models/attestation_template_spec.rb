describe AttestationTemplate, type: :model do
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
        expect(subject.logo.attachment).not_to eq(attestation_template.logo.attachment)
        expect(subject.logo.blob).to eq(attestation_template.logo.blob)
        expect(subject.logo.attached?).to be_truthy
      end

      it do
        expect(subject.signature.attachment).not_to eq(attestation_template.signature.attachment)
        expect(subject.signature.blob).to eq(attestation_template.signature.blob)
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
        types_de_champ_public: types_de_champ,
        types_de_champ_private: types_de_champ_private,
        for_individual: for_individual,
        attestation_template: attestation_template)
    end
    let(:for_individual) { false }
    let(:individual) { nil }
    let(:etablissement) { create(:etablissement) }
    let(:types_de_champ) { [] }
    let(:types_de_champ_private) { [] }
    let!(:dossier) { create(:dossier, procedure: procedure, individual: individual, etablissement: etablissement) }
    let(:template_title) { 'title' }
    let(:template_body) { 'body' }
    let(:attestation_template) { build(:attestation_template, :with_files, title: template_title, body: template_body) }

    before do
      Timecop.freeze(Time.zone.now)
    end

    after do
      Timecop.return
    end

    let(:view_args) do
      arguments = nil

      allow(ApplicationController).to receive(:render).and_wrap_original do |m, *args|
        arguments = args.first[:assigns]
        m.call(*args)
      end

      attestation_template.attestation_for(dossier)

      arguments
    end

    let(:attestation) { attestation_template.attestation_for(dossier) }

    context "when the attestation has a logo but our storage is down" do
      before { require 'fog/openstack' }

      it 'retries once' do
        call_count = 0
        allow(attestation_template.logo).to receive(:download) do
          if call_count == 0
            call_count += 1
            raise Fog::OpenStack::Storage::NotFound.new('Object storage 99.99% availability leave space to 0.01% failure')
          else
            attestation_template.logo.blob.download
          end
        end
        expect(attestation.pdf).to be_attached
      end
    end

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ) do
        [
          { libelle: 'libelleA' },
          { libelle: 'libelleB' }
        ]
      end

      context 'and they are used in the template title and body' do
        let(:template_title) { 'title --libelleA--' }
        let(:template_body) { 'body --libelleB--' }

        context 'and their value in the dossier are not nil' do
          before do
            dossier.champs_public
              .find { |champ| champ.libelle == 'libelleA' }
              .update(value: 'libelle1')

            dossier.champs_public
              .find { |champ| champ.libelle == 'libelleB' }
              .update(value: 'libelle2')
          end

          it 'passes the correct parameters to the view' do
            expect(view_args[:attestation][:title]).to eq('title libelle1')
            expect(view_args[:attestation][:body]).to eq('body libelle2')
          end

          it 'generates an attestation' do
            expect(attestation.title).to eq('title libelle1')
            expect(attestation.pdf).to be_attached
          end
        end
      end
    end
  end
end
