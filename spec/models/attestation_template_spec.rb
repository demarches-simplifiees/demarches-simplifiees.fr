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

      it "works" do
        is_expected.to have_attributes(attributes)
        is_expected.to have_attributes(id: nil)
        expect(subject.logo.attached?).to be_falsey
      end
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
        attestation_template: attestation_template)
    end
    let(:etablissement) { create(:etablissement) }
    let(:types_de_champ) { [] }
    let(:types_de_champ_private) { [] }
    let(:dossier) { create(:dossier, :accepte, procedure:) }

    let(:types_de_champ) do
      [
        { libelle: 'libelleA' },
        { libelle: 'libelleB' }
      ]
    end

    before do
      dossier.champs_public
        .find { |champ| champ.libelle == 'libelleA' }
        .update(value: 'libelle1')

      dossier.champs_public
        .find { |champ| champ.libelle == 'libelleB' }
        .update(value: 'libelle2')
    end

    let(:attestation) { attestation_template.attestation_for(dossier) }

    context 'attestation v1' do
      let(:template_title) { 'title --libelleA--' }
      let(:template_body) { 'body --libelleB--' }
      let(:attestation_template) do
        build(:attestation_template,
          title: template_title,
          body: template_body)
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

      it 'passes the correct parameters and generates an attestation' do
        expect(view_args[:attestation][:title]).to eq('title libelle1')
        expect(view_args[:attestation][:body]).to eq('body libelle2')
        expect(attestation.title).to eq('title libelle1')
        expect(attestation.pdf).to be_attached
      end
    end

    context 'attestation v2' do
      let(:attestation_template) do
        build(:attestation_template, :v2, :with_files, label_logo: "Ministère des specs")
      end

      before do
        stub_request(:post, WEASYPRINT_URL)
          .with(body: {
            html: /Ministère des specs.+Mon titre pour #{procedure.libelle}.+Dossier: n° #{dossier.id}/m,
            upstream_context: { procedure_id: procedure.id, dossier_id: dossier.id }
          })
          .to_return(body: 'PDF_DATA')
      end

      it 'generates an attestation' do
        expect(attestation.pdf).to be_attached
      end
    end
  end

  describe '#render_attributes_for' do
    context 'signature' do
      let(:dossier) { create(:dossier, procedure: attestation.procedure, groupe_instructeur: groupe_instructeur) }

      subject { attestation.render_attributes_for(dossier: dossier)[:signature] }

      context 'procedure with signature' do
        let(:attestation) { create(:attestation_template, signature: Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png')) }

        context "groupe instructeur without signature" do
          let(:groupe_instructeur) { create(:groupe_instructeur, signature: nil) }

          it { expect(subject.blob.filename).to eq("logo_test_procedure.png") }
        end

        context 'groupe instructeur with signature' do
          let(:groupe_instructeur) { create(:groupe_instructeur, signature: Rack::Test::UploadedFile.new('spec/fixtures/files/black.png', 'image/png')) }

          it { expect(subject.blob.filename).to eq("black.png") }
        end
      end

      context 'procedure without signature' do
        let(:attestation) { create(:attestation_template, signature: nil) }

        context "groupe instructeur without signature" do
          let(:groupe_instructeur) { create(:groupe_instructeur, signature: nil) }

          it { expect(subject.attached?).to be_falsey }
        end

        context 'groupe instructeur with signature' do
          let(:groupe_instructeur) { create(:groupe_instructeur, signature: Rack::Test::UploadedFile.new('spec/fixtures/files/black.png', 'image/png')) }

          it { expect(subject.blob.filename).to eq("black.png") }
        end
      end
    end

    context 'body v2' do
      let(:attestation) { create(:attestation_template, :v2) }
      let(:dossier) { create(:dossier, procedure: attestation.procedure, individual: build(:individual, nom: 'Doe', prenom: 'John')) }

      it do
        body = attestation.render_attributes_for(dossier: dossier)[:body]
        expect(body).to include("Mon titre pour #{dossier.procedure.libelle}")
        expect(body).to include("Doe John")
      end
    end
  end
end
