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

    context 'when the dossier and the procedure has an individual' do
      let(:for_individual) { true }
      let(:individual) { Individual.create(nom: 'nom', prenom: 'prenom', gender: 'Mme') }

      context 'and the template title use the individual tags' do
        let(:template_title) { '--civilité-- --nom-- --prénom--' }

        it { expect(view_args[:title]).to eq('Mme nom prenom') }
      end
    end

    context 'when the dossier and the procedure has an entreprise' do
      let(:for_individual) { false }

      context 'and the template title use the entreprise tags' do
        let(:template_title) do
          '--SIREN-- --numéro de TVA intracommunautaire-- --SIRET du siège social-- --raison sociale-- --adresse--'
        end

        let(:expected_title) do
          "#{entreprise.siren} #{entreprise.numero_tva_intracommunautaire} #{entreprise.siret_siege_social} #{entreprise.raison_sociale} --adresse--"
        end

        it { expect(view_args[:title]).to eq(expected_title) }

        context 'and the entreprise has a etablissement with an adresse' do
          let(:etablissement) { create(:etablissement, adresse: 'adresse') }
          let(:template_title) { '--adresse--' }

          it { expect(view_args[:title]).to eq(etablissement.inline_adresse) }
        end
      end
    end

    context 'when the procedure has a type de champ named libelleA et libelleB' do
      let(:types_de_champ) do
        [create(:type_de_champ_public, libelle: 'libelleA'),
         create(:type_de_champ_public, libelle: 'libelleB')]
      end

      context 'and the template title is nil' do
        let(:template_title) { nil }

        it { expect(view_args[:title]).to eq('') }
      end

      context 'and it is not used in the template title nor body' do
        it { expect(view_args[:title]).to eq('title') }
        it { expect(view_args[:body]).to eq('body') }
        it { expect(view_args[:created_at]).to eq(Time.now) }
        it { expect(view_args[:logo]).to eq(attestation_template.logo) }
        it { expect(view_args[:signature]).to eq(attestation_template.signature) }
      end

      context 'and the are used in the template title and body' do
        let(:template_title) { 'title --libelleA--' }
        let(:template_body) { 'body --libelleB--' }

        context 'and their value in the dossier are nil' do
          it { expect(view_args[:title]).to eq('title ') }
        end

        context 'and their value in the dossier are not nil' do
          before :each do
            dossier.champs
              .select { |champ| champ.libelle == 'libelleA' }
              .first
              .value = 'libelle1'

            dossier.champs
              .select { |champ| champ.libelle == 'libelleB' }
              .first
              .value = 'libelle2'
          end

          it { expect(view_args[:title]).to eq('title libelle1') }
          it { expect(view_args[:body]).to eq('body libelle2') }
          it { expect(attestation.title).to eq('title libelle1') }
        end
      end
    end

    context 'when the dossier has a motivation' do
      let(:dossier) { create(:dossier, motivation: 'motivation') }

      context 'and the title has some dossier tags' do
        let(:template_title) { 'title --motivation-- --numéro du dossier--' }

        it { expect(view_args[:title]).to eq("title motivation #{dossier.id}") }
      end
    end

    context 'when the procedure has a type de champ prive named libelleA' do
      let(:types_de_champ_private) { [create(:type_de_champ_private, libelle: 'libelleA')] }

      context 'and the are used in the template title' do
        let(:template_title) { 'title --libelleA--' }

        context 'and its value in the dossier are not nil' do
          before :each do
            dossier.champs_private
              .select { |champ| champ.libelle == 'libelleA' }
              .first
              .value = 'libelle1'
          end

          it { expect(view_args[:title]).to eq('title libelle1') }
        end
      end
    end

    context 'when the procedure has 2 types de champ date and datetime' do
      let(:types_de_champ) do
        [create(:type_de_champ_public, libelle: 'date', type_champ: 'date'),
         create(:type_de_champ_public, libelle: 'datetime', type_champ: 'datetime')]
      end

      context 'and the are used in the template title' do
        let(:template_title) { 'title --date-- --datetime--' }

        context 'and its value in the dossier are not nil' do
          before :each do
            dossier.champs
              .select { |champ| champ.type_champ == 'date' }
              .first
              .value = '2017-04-15'

            dossier.champs
              .select { |champ| champ.type_champ == 'datetime' }
              .first
              .value = '13/09/2017 09:00'
          end

          it { expect(view_args[:title]).to eq('title 15/04/2017 13/09/2017 09:00') }
        end
      end
    end

    context "match breaking and non breaking spaces" do
      before do
        c = dossier.champs.first
        c.value = 'valeur'
        c.save
      end

      context "when the tag contains a non breaking space" do
        let(:template_body) { 'body --mon tag--' }

        context 'and the champ contains the non breaking space' do
          let(:types_de_champ) { [create(:type_de_champ_public, libelle: 'mon tag')] }

          it { expect(view_args[:body]).to eq('body valeur') }
        end

        context 'and the champ has an ordinary space' do
          let(:types_de_champ) { [create(:type_de_champ_public, libelle: 'mon tag')] }

          it { expect(view_args[:body]).to eq('body valeur') }
        end
      end

      context "when the tag contains an ordinay space" do
        let(:template_body) { 'body --mon tag--' }

        context 'and the champ contains a non breaking space' do
          let(:types_de_champ) { [create(:type_de_champ_public, libelle: 'mon tag')] }

          it { expect(view_args[:body]).to eq('body valeur') }
        end

        context 'and the champ has an ordinary space' do
          let(:types_de_champ) { [create(:type_de_champ_public, libelle: 'mon tag')] }

          it { expect(view_args[:body]).to eq('body valeur') }
        end
      end
    end
  end
end
