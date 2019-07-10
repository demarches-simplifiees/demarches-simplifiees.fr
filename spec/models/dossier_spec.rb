require 'spec_helper'

describe Dossier do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  describe "without_followers scope" do
    let!(:dossier) { create(:dossier, :followed, :with_entreprise, user: user) }
    let!(:dossier2) { create(:dossier, :with_entreprise, user: user) }

    it { expect(Dossier.without_followers.to_a).to eq([dossier2]) }
  end

  describe 'with_champs' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { Dossier.create(user: create(:user), procedure: procedure) }

    before do
      create(:type_de_champ, libelle: 'l1', order_place: 1, procedure: procedure)
      create(:type_de_champ, libelle: 'l3', order_place: 3, procedure: procedure)
      create(:type_de_champ, libelle: 'l2', order_place: 2, procedure: procedure)
    end

    it do
      expect(Dossier.with_champs.find(dossier.id).champs.map(&:libelle)).to match(['l1', 'l2', 'l3'])
    end
  end

  describe 'nearing_end_of_retention' do
    let(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds: 6) }
    let!(:young_dossier) { create(:dossier, procedure: procedure) }
    let!(:expiring_dossier) { create(:dossier, :en_instruction, en_instruction_at: 170.days.ago, procedure: procedure) }
    let!(:just_expired_dossier) { create(:dossier, :en_instruction, en_instruction_at: (6.months + 1.hour + 10.seconds).ago, procedure: procedure) }
    let!(:long_expired_dossier) { create(:dossier, :en_instruction, en_instruction_at: 1.year.ago, procedure: procedure) }

    context 'with default delay to end of retention' do
      subject { Dossier.nearing_end_of_retention }

      it { is_expected.not_to include(young_dossier) }
      it { is_expected.to include(expiring_dossier) }
      it { is_expected.to include(just_expired_dossier) }
      it { is_expected.to include(long_expired_dossier) }
    end

    context 'with custom delay to end of retention' do
      subject { Dossier.nearing_end_of_retention('0') }

      it { is_expected.not_to include(young_dossier) }
      it { is_expected.not_to include(expiring_dossier) }
      it { is_expected.to include(just_expired_dossier) }
      it { is_expected.to include(long_expired_dossier) }
    end
  end

  describe 'methods' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }
    let(:etablissement) { dossier.etablissement }

    subject { dossier }

    describe '#update_search_terms' do
      let(:etablissement) { build(:etablissement, entreprise_nom: 'Dupont', entreprise_prenom: 'Thomas', association_rna: '12345', association_titre: 'asso de test', association_objet: 'tests unitaires') }
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
      let(:dossier) { create(:dossier, etablissement: etablissement, user: user, procedure: procedure) }
      let(:france_connect_information) { build(:france_connect_information, given_name: 'Chris', family_name: 'Harrisson') }
      let(:user) { build(:user, france_connect_information: france_connect_information) }
      let(:champ_public) { dossier.champs.first }
      let(:champ_private) { dossier.champs_private.first }

      before do
        champ_public.update_attribute(:value, "champ public")
        champ_private.update_attribute(:value, "champ privé")

        dossier.update_search_terms
      end

      it { expect(dossier.search_terms).to eq("#{user.email} champ public #{etablissement.entreprise_siren} #{etablissement.entreprise_numero_tva_intracommunautaire} #{etablissement.entreprise_forme_juridique} #{etablissement.entreprise_forme_juridique_code} #{etablissement.entreprise_nom_commercial} #{etablissement.entreprise_raison_sociale} #{etablissement.entreprise_siret_siege_social} #{etablissement.entreprise_nom} #{etablissement.entreprise_prenom} #{etablissement.association_rna} #{etablissement.association_titre} #{etablissement.association_objet} #{etablissement.siret} #{etablissement.naf} #{etablissement.libelle_naf} #{etablissement.adresse} #{etablissement.code_postal} #{etablissement.localite} #{etablissement.code_insee_localite}") }
      it { expect(dossier.private_search_terms).to eq('champ privé') }

      context 'with an update' do
        before do
          dossier.update(
            champs_attributes: [{ id: champ_public.id, value: 'nouvelle valeur publique' }],
            champs_private_attributes: [{ id: champ_private.id, value: 'nouvelle valeur privee' }]
          )
        end

        it { expect(dossier.search_terms).to include('nouvelle valeur publique') }
        it { expect(dossier.private_search_terms).to include('nouvelle valeur privee') }
      end
    end

    describe '#types_de_piece_justificative' do
      subject { dossier.types_de_piece_justificative }
      it 'returns list of required piece justificative' do
        expect(subject.size).to eq(2)
        expect(subject).to include(TypeDePieceJustificative.find(TypeDePieceJustificative.first.id))
      end
    end

    describe '#retrieve_last_piece_justificative_by_type', vcr: { cassette_name: 'models_dossier_retrieve_last_piece_justificative_by_type' } do
      let(:types_de_pj_dossier) { dossier.procedure.types_de_piece_justificative }

      subject { dossier.retrieve_last_piece_justificative_by_type types_de_pj_dossier.first }

      before do
        create :piece_justificative, :rib, dossier: dossier, type_de_piece_justificative: types_de_pj_dossier.first
      end

      it 'returns piece justificative with given type' do
        expect(subject.type).to eq(types_de_pj_dossier.first.id)
      end
    end

    describe '#build_default_champs' do
      context 'when dossier is linked to a procedure with type_de_champ_public and private' do
        let(:dossier) { create(:dossier, user: user) }

        it 'build all champs needed' do
          expect(dossier.champs.count).to eq(1)
        end

        it 'build all champs_private needed' do
          expect(dossier.champs_private.count).to eq(1)
        end
      end
    end

    describe '#build_default_individual' do
      context 'when dossier is linked to a procedure with for_individual attr false' do
        let(:dossier) { create(:dossier, user: user) }

        it 'have no object created' do
          expect(dossier.individual).to be_nil
        end
      end

      context 'when dossier is linked to a procedure with for_individual attr true' do
        let(:dossier) { create(:dossier, user: user, procedure: (create :procedure, for_individual: true)) }

        it 'have no object created' do
          expect(dossier.individual).not_to be_nil
        end
      end
    end

    describe '#save' do
      subject { build(:dossier, procedure: procedure, user: user) }
      let!(:procedure) { create(:procedure) }

      context 'when is linked to a procedure' do
        it 'creates default champs' do
          expect(subject).to receive(:build_default_champs)
          subject.save
        end
      end
      context 'when is not linked to a procedure' do
        subject { create(:dossier, procedure: nil, user: user) }

        it 'does not create default champs' do
          expect(subject).not_to receive(:build_default_champs)
          subject.update(state: Dossier.states.fetch(:en_construction))
        end
      end
    end
  end

  context 'when dossier is followed' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:date1) { 1.day.ago }
    let(:date2) { 1.hour.ago }
    let(:date3) { 1.minute.ago }
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure, en_construction_at: date1, en_instruction_at: date2, processed_at: date3, motivation: "Motivation") }
    let!(:follow) { create(:follow, gestionnaire: gestionnaire, dossier: dossier) }

    describe "followers_gestionnaires" do
      let(:non_following_gestionnaire) { create(:gestionnaire) }
      subject { dossier.followers_gestionnaires }

      it { expect(subject).to eq [gestionnaire] }
      it { expect(subject).not_to include(non_following_gestionnaire) }
    end
  end

  describe '#reset!' do
    let!(:dossier) { create :dossier, :with_entreprise, autorisation_donnees: true }
    let!(:exercice) { create :exercice, etablissement: dossier.etablissement }

    subject { dossier.reset! }

    it { expect(dossier.etablissement).not_to be_nil }
    it { expect(dossier.etablissement.exercices).not_to be_empty }
    it { expect(dossier.etablissement.exercices.size).to eq 1 }
    it { expect(dossier.autorisation_donnees).to be_truthy }

    it { expect { subject }.to change(Exercice, :count).by(-1) }
    it { expect { subject }.to change(Etablissement, :count).by(-1) }

    context 'when method reset! is call' do
      before do
        subject
        dossier.reload
      end

      it { expect(dossier.etablissement).to be_nil }
      it { expect(dossier.autorisation_donnees).to be_falsey }
    end
  end

  describe '#champs' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { Dossier.create(user: create(:user), procedure: procedure) }

    before do
      create(:type_de_champ, libelle: 'l1', order_place: 1, procedure: procedure)
      create(:type_de_champ, libelle: 'l3', order_place: 3, procedure: procedure)
      create(:type_de_champ, libelle: 'l2', order_place: 2, procedure: procedure)
    end

    it { expect(dossier.champs.pluck(:libelle)).to match(['l1', 'l2', 'l3']) }
  end

  describe '#champs_private' do
    let(:procedure) { create :procedure }
    let(:dossier) { Dossier.create(user: create(:user), procedure: procedure) }

    before do
      create :type_de_champ, :private, libelle: 'l1', order_place: 1, procedure: procedure
      create :type_de_champ, :private, libelle: 'l3', order_place: 3, procedure: procedure
      create :type_de_champ, :private, libelle: 'l2', order_place: 2, procedure: procedure
    end

    it { expect(dossier.champs_private.pluck(:libelle)).to match(['l1', 'l2', 'l3']) }
  end

  describe "#text_summary" do
    let(:service) { create(:service, nom: 'nom du service') }
    let(:procedure) { create(:procedure, libelle: "Démarche", organisation: "Organisme", service: service) }

    context 'when the dossier has been en_construction' do
      let(:dossier) { create :dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), en_construction_at: "31/12/2010".to_date }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier déposé le 31/12/2010 sur la démarche Démarche gérée par l'organisme nom du service") }
    end

    context 'when the dossier has not been en_construction' do
      let(:dossier) { create :dossier, procedure: procedure, state: Dossier.states.fetch(:brouillon) }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier en brouillon répondant à la démarche Démarche gérée par l'organisme nom du service") }
    end
  end

  describe '#avis_for' do
    let!(:procedure) { create(:procedure, :published) }
    let!(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)) }

    let!(:gestionnaire) { create(:gestionnaire, procedures: [procedure]) }
    let!(:expert_1) { create(:gestionnaire) }
    let!(:expert_2) { create(:gestionnaire) }

    context 'when there is a public advice asked from the dossiers gestionnaire' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: gestionnaire, gestionnaire: expert_1, confidentiel: false) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([avis]) }
    end

    context 'when there is a private advice asked from the dossiers gestionnaire' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: gestionnaire, gestionnaire: expert_1, confidentiel: true) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([]) }
    end

    context 'when there is a public advice asked from one expert to another' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([avis]) }
    end

    context 'when there is a private advice asked from one expert to another' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: true) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([avis]) }
    end

    context 'when they are a lot of advice' do
      let!(:avis_1) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false, created_at: Time.zone.parse('10/01/2010')) }
      let!(:avis_2) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false, created_at: Time.zone.parse('9/01/2010')) }
      let!(:avis_3) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false, created_at: Time.zone.parse('11/01/2010')) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis_2, avis_1, avis_3]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis_2, avis_1, avis_3]) }
    end
  end

  describe '#update_state_dates' do
    let(:state) { Dossier.states.fetch(:brouillon) }
    let(:dossier) { create(:dossier, state: state) }
    let(:beginning_of_day) { Time.zone.now.beginning_of_day }

    before { Timecop.freeze(beginning_of_day) }
    after { Timecop.return }

    context 'when dossier is en_construction' do
      before do
        dossier.en_construction!
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:en_construction)) }
      it { expect(dossier.en_construction_at).to eq(beginning_of_day) }

      it 'should keep first en_construction_at date' do
        Timecop.return
        dossier.en_instruction!
        dossier.en_construction!

        expect(dossier.en_construction_at).to eq(beginning_of_day)
      end
    end

    context 'when dossier is en_instruction' do
      let(:state) { Dossier.states.fetch(:en_construction) }

      before do
        dossier.en_instruction!
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction)) }
      it { expect(dossier.en_instruction_at).to eq(beginning_of_day) }

      it 'should keep first en_instruction_at date if dossier is set to en_construction again' do
        Timecop.return
        dossier.en_construction!
        dossier.en_instruction!

        expect(dossier.en_instruction_at).to eq(beginning_of_day)
      end
    end

    shared_examples 'dossier is processed' do |new_state|
      before do
        dossier.update(state: new_state)
        dossier.reload
      end

      it { expect(dossier.state).to eq(new_state) }
      it { expect(dossier.processed_at).to eq(beginning_of_day) }
    end

    context 'when dossier is accepte' do
      let(:state) { Dossier.states.fetch(:en_instruction) }

      it_behaves_like 'dossier is processed', Dossier.states.fetch(:accepte)
    end

    context 'when dossier is refuse' do
      let(:state) { Dossier.states.fetch(:en_instruction) }

      it_behaves_like 'dossier is processed', Dossier.states.fetch(:refuse)
    end

    context 'when dossier is sans_suite' do
      let(:state) { Dossier.states.fetch(:en_instruction) }

      it_behaves_like 'dossier is processed', Dossier.states.fetch(:sans_suite)
    end
  end

  describe '.downloadable_sorted' do
    let(:procedure) { create(:procedure) }
    let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:brouillon)) }
    let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:en_construction), en_construction_at: Time.zone.parse('03/01/2010')) }
    let!(:dossier3) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:en_instruction), en_construction_at: Time.zone.parse('01/01/2010')) }
    let!(:dossier4) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:en_instruction), archived: true, en_construction_at: Time.zone.parse('02/01/2010')) }

    subject { procedure.dossiers.downloadable_sorted }

    it { is_expected.to match([dossier3, dossier4, dossier2]) }
  end

  describe "#send_dossier_received" do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)) }

    before do
      allow(NotificationMailer).to receive(:send_dossier_received).and_return(double(deliver_later: nil))
    end

    it "sends an email when the dossier becomes en_instruction" do
      dossier.en_instruction!
      expect(NotificationMailer).to have_received(:send_dossier_received).with(dossier)
    end

    it "does not an email when the dossier becomes accepte" do
      dossier.accepte!
      expect(NotificationMailer).to_not have_received(:send_dossier_received)
    end
  end

  describe "#send_draft_notification_email" do
    include Rails.application.routes.url_helpers

    let(:procedure) { create(:procedure) }
    let(:user) { create(:user) }

    it "send an email when the dossier is created for the very first time" do
      dossier = nil
      ActiveJob::Base.queue_adapter = :test
      expect do
        perform_enqueued_jobs do
          dossier = Dossier.create(procedure: procedure, state: Dossier.states.fetch(:brouillon), user: user)
        end
      end.to change(ActionMailer::Base.deliveries, :size).from(0).to(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq("Retrouvez votre brouillon pour la démarche \"#{procedure.libelle}\"")
      expect(mail.html_part.body).to include(dossier_url(dossier))
    end

    it "does not send an email when the dossier is created with a non brouillon state" do
      expect { Dossier.create(procedure: procedure, state: Dossier.states.fetch(:en_construction), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: Dossier.states.fetch(:en_instruction), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: Dossier.states.fetch(:accepte), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: Dossier.states.fetch(:refuse), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: Dossier.states.fetch(:sans_suite), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
    end
  end

  describe "#unspecified_attestation_champs" do
    let(:procedure) { create(:procedure, attestation_template: attestation_template) }
    let(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }

    subject { dossier.unspecified_attestation_champs.map(&:libelle) }

    context "without attestation template" do
      let(:attestation_template) { nil }

      it { is_expected.to eq([]) }
    end

    context "with attestation template" do
      # Test all combinations:
      # - with tag specified and unspecified
      # - with tag in body and tag in title
      # - with tag correponsing to a champ and an annotation privée
      # - with a dash in the champ libelle / tag
      let(:title) { "voici --specified champ-in-title-- un --unspecified champ-in-title-- beau --specified annotation privée-in-title-- titre --unspecified annotation privée-in-title-- non --numéro du dossier--" }
      let(:body) { "voici --specified champ-in-body-- un --unspecified champ-in-body-- beau --specified annotation privée-in-body-- body --unspecified annotation privée-in-body-- non ?" }
      let(:attestation_template) { create(:attestation_template, title: title, body: body, activated: activated) }

      context "which is disabled" do
        let(:activated) { false }

        it { is_expected.to eq([]) }
      end

      context "wich is enabled" do
        let(:activated) { true }

        let!(:tdc_1) { create(:type_de_champ, libelle: "specified champ-in-title", procedure: procedure) }
        let!(:tdc_2) { create(:type_de_champ, libelle: "unspecified champ-in-title", procedure: procedure) }
        let!(:tdc_3) { create(:type_de_champ, libelle: "specified champ-in-body", procedure: procedure) }
        let!(:tdc_4) { create(:type_de_champ, libelle: "unspecified champ-in-body", procedure: procedure) }
        let!(:tdc_5) { create(:type_de_champ, private: true, libelle: "specified annotation privée-in-title", procedure: procedure) }
        let!(:tdc_6) { create(:type_de_champ, private: true, libelle: "unspecified annotation privée-in-title", procedure: procedure) }
        let!(:tdc_7) { create(:type_de_champ, private: true, libelle: "specified annotation privée-in-body", procedure: procedure) }
        let!(:tdc_8) { create(:type_de_champ, private: true, libelle: "unspecified annotation privée-in-body", procedure: procedure) }

        before do
          (dossier.champs + dossier.champs_private)
            .select { |c| c.libelle.match?(/^specified/) }
            .each { |c| c.update_attribute(:value, "specified") }
        end

        it do
          is_expected.to eq([
            "unspecified champ-in-title",
            "unspecified annotation privée-in-title",
            "unspecified champ-in-body",
            "unspecified annotation privée-in-body"
          ])
        end
      end
    end
  end

  describe '#build_attestation' do
    let(:attestation_template) { nil }
    let(:procedure) { create(:procedure, attestation_template: attestation_template) }

    before :each do
      dossier.attestation = dossier.build_attestation
      dossier.reload
    end

    context 'when the dossier is in en_instruction state ' do
      let!(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }

      context 'when the procedure has no attestation' do
        it { expect(dossier.attestation).to be_nil }
      end

      context 'when the procedure has an unactivated attestation' do
        let(:attestation_template) { AttestationTemplate.new(activated: false) }

        it { expect(dossier.attestation).to be_nil }
      end

      context 'when the procedure attached has an activated attestation' do
        let(:attestation_template) { AttestationTemplate.new(activated: true) }

        it { expect(dossier.attestation).not_to be_nil }
      end
    end
  end

  describe ".default_scope" do
    let!(:dossier) { create(:dossier, hidden_at: hidden_at) }

    context "when dossier is not hidden" do
      let(:hidden_at) { nil }

      it { expect(Dossier.count).to eq(1) }
      it { expect(Dossier.all).to include(dossier) }
    end

    context "when dossier is hidden" do
      let(:hidden_at) { 1.day.ago }

      it { expect(Dossier.count).to eq(0) }
    end
  end

  describe 'updated_at' do
    let!(:dossier) { create(:dossier) }
    let(:modif_date) { Time.zone.parse('01/01/2100') }

    before { Timecop.freeze(modif_date) }
    after { Timecop.return }

    subject do
      dossier.reload
      dossier.updated_at
    end

    it { is_expected.not_to eq(modif_date) }

    context 'when a piece justificative is modified' do
      before { dossier.pieces_justificatives << create(:piece_justificative, :contrat) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a champ is modified' do
      before { dossier.champs.first.update_attribute('value', 'yop') }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a commentaire is modified' do
      before { dossier.commentaires << create(:commentaire) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when an avis is modified' do
      before { dossier.avis << create(:avis) }

      it { is_expected.to eq(modif_date) }
    end
  end

  describe '#owner_name' do
    let!(:procedure) { create(:procedure) }
    subject { dossier.owner_name }

    context 'when there is no entreprise or individual' do
      let(:dossier) { create(:dossier, individual: nil, procedure: procedure) }

      it { is_expected.to be_nil }
    end

    context 'when there is entreprise' do
      let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }

      it { is_expected.to eq(dossier.etablissement.entreprise_raison_sociale) }
    end

    context 'when there is an individual' do
      let(:dossier) { create(:dossier, :for_individual, procedure: procedure) }

      it { is_expected.to eq("#{dossier.individual.nom} #{dossier.individual.prenom}") }
    end
  end

  describe "#delete_and_keep_track" do
    let(:dossier) { create(:dossier) }
    let(:deleted_dossier) { DeletedDossier.find_by!(dossier_id: dossier.id) }

    before do
      allow(DossierMailer).to receive(:notify_deletion_to_user).and_return(double(deliver_later: nil))
      allow(DossierMailer).to receive(:notify_deletion_to_administration).and_return(double(deliver_later: nil))
    end

    subject! { dossier.delete_and_keep_track }

    it 'hides the dossier' do
      expect(dossier.hidden_at).to be_present
    end

    it 'creates a DeletedDossier record' do
      expect(deleted_dossier.dossier_id).to eq dossier.id
      expect(deleted_dossier.procedure).to eq dossier.procedure
      expect(deleted_dossier.state).to eq dossier.state
      expect(deleted_dossier.deleted_at).to be_present
    end

    it 'notifies the user' do
      expect(DossierMailer).to have_received(:notify_deletion_to_user).with(deleted_dossier, dossier.user.email)
    end

    context 'where gestionnaires are following the dossier' do
      let(:dossier) { create(:dossier, :en_construction, :followed) }
      let!(:non_following_gestionnaire) do
        non_following_gestionnaire = create(:gestionnaire)
        non_following_gestionnaire.procedures << dossier.procedure
        non_following_gestionnaire
      end

      it 'notifies the following gestionnaires' do
        expect(DossierMailer).to have_received(:notify_deletion_to_administration).once
        expect(DossierMailer).to have_received(:notify_deletion_to_administration).with(deleted_dossier, dossier.followers_gestionnaires.first.email)
      end
    end

    context 'when there are no following gestionnaires' do
      let(:dossier) { create(:dossier, :en_construction) }
      it 'notifies the procedure administrateur' do
        expect(DossierMailer).to have_received(:notify_deletion_to_administration).once
        expect(DossierMailer).to have_received(:notify_deletion_to_administration).with(deleted_dossier, dossier.procedure.administrateurs.first.email)
      end
    end

    context 'when dossier is brouillon' do
      let(:dossier) { create(:dossier) }
      it 'do not notifies the procedure administrateur' do
        expect(DossierMailer).not_to have_received(:notify_deletion_to_administration)
      end
    end
  end

  describe 'webhook' do
    let(:dossier) { create(:dossier) }

    it 'should not call webhook' do
      expect {
        dossier.accepte!
      }.to_not have_enqueued_job(WebHookJob)
    end

    it 'should call webhook' do
      dossier.procedure.update_column(:web_hook_url, '/webhook.json')

      expect {
        dossier.update_column(:motivation, 'bonjour')
      }.to_not have_enqueued_job(WebHookJob)

      expect {
        dossier.en_construction!
      }.to have_enqueued_job(WebHookJob)

      expect {
        dossier.update_column(:motivation, 'bonjour2')
      }.to_not have_enqueued_job(WebHookJob)

      expect {
        dossier.en_instruction!
      }.to have_enqueued_job(WebHookJob)
    end
  end

  describe "#can_transition_to_en_construction?" do
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, state: state, procedure: procedure) }

    subject { dossier.can_transition_to_en_construction? }

    context "dossier state is brouillon" do
      let(:state) { Dossier.states.fetch(:brouillon) }
      it { is_expected.to be true }

      context "procedure is archived" do
        before { procedure.archive }
        it { is_expected.to be false }
      end
    end

    context "dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:en_construction) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:en_instruction) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:accepte) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:refuse) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:sans_suite) }
      it { is_expected.to be false }
    end
  end

  describe "#messagerie_available?" do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    subject { dossier.messagerie_available? }

    context "dossier is brouillon" do
      before { dossier.state = Dossier.states.fetch(:brouillon) }

      it { is_expected.to be false }
    end

    context "dossier is archived" do
      before { dossier.archived = true }

      it { is_expected.to be false }
    end

    context "procedure is archived" do
      before { procedure.archived_at = Date.today }

      it { is_expected.to be false }
    end

    context "procedure is not archived, dossier is not archived" do
      before { dossier.state = Dossier.states.fetch(:en_instruction) }

      it { is_expected.to be true }
    end
  end

  context "retention date" do
    let(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds: 6) }
    let(:uninstructed_dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let(:young_dossier) { create(:dossier, :en_instruction, en_instruction_at: Time.zone.now, procedure: procedure) }
    let(:just_expired_dossier) { create(:dossier, :en_instruction, en_instruction_at: 6.months.ago, procedure: procedure) }
    let(:long_expired_dossier) { create(:dossier, :en_instruction, en_instruction_at: 1.year.ago, procedure: procedure) }
    let(:modif_date) { Time.zone.parse('01/01/2100') }

    before { Timecop.freeze(modif_date) }
    after { Timecop.return }

    describe "#retention_end_date" do
      it { expect(uninstructed_dossier.retention_end_date).to be_nil }
      it { expect(young_dossier.retention_end_date).to eq(6.months.from_now) }
      it { expect(just_expired_dossier.retention_end_date).to eq(Time.zone.now) }
      it { expect(long_expired_dossier.retention_end_date).to eq(6.months.ago) }
    end

    describe "#retention_expired?" do
      it { expect(uninstructed_dossier).not_to be_retention_expired }
      it { expect(young_dossier).not_to be_retention_expired }
      it { expect(just_expired_dossier).to be_retention_expired }
      it { expect(long_expired_dossier).to be_retention_expired }
    end
  end

  describe '#accepter!' do
    let(:dossier) { create(:dossier, :en_instruction) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:operation_serialized) { JSON.parse(last_operation.serialized.download) }
    let!(:gestionnaire) { create(:gestionnaire) }
    let!(:now) { Time.zone.parse('01/01/2100') }
    let(:attestation) { Attestation.new }

    before do
      allow(NotificationMailer).to receive(:send_closed_notification).and_return(double(deliver_later: true))
      allow(dossier).to receive(:build_attestation).and_return(attestation)

      Timecop.freeze(now)
      dossier.accepter!(gestionnaire, 'motivation')
      dossier.reload
    end

    after { Timecop.return }

    it { expect(dossier.motivation).to eq('motivation') }
    it { expect(dossier.en_instruction_at).to eq(dossier.en_instruction_at) }
    it { expect(dossier.processed_at).to eq(now) }
    it { expect(dossier.state).to eq('accepte') }
    it { expect(last_operation.operation).to eq('accepter') }
    it { expect(last_operation.automatic_operation?).to be_falsey }
    it { expect(operation_serialized['operation']).to eq('accepter') }
    it { expect(operation_serialized['dossier_id']).to eq(dossier.id) }
    it { expect(operation_serialized['executed_at']).to eq(last_operation.executed_at.iso8601) }
    it { expect(NotificationMailer).to have_received(:send_closed_notification).with(dossier) }
    it { expect(dossier.attestation).to eq(attestation) }
  end

  describe '#accepter_automatiquement!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let!(:now) { Time.zone.parse('01/01/2100') }
    let(:attestation) { Attestation.new }

    before do
      allow(NotificationMailer).to receive(:send_closed_notification).and_return(double(deliver_later: true))
      allow(dossier).to receive(:build_attestation).and_return(attestation)

      Timecop.freeze(now)
      dossier.accepter_automatiquement!
      dossier.reload
    end

    after { Timecop.return }

    it { expect(dossier.motivation).to eq(nil) }
    it { expect(dossier.en_instruction_at).to eq(now) }
    it { expect(dossier.processed_at).to eq(now) }
    it { expect(dossier.state).to eq('accepte') }
    it { expect(last_operation.operation).to eq('accepter') }
    it { expect(last_operation.automatic_operation?).to be_truthy }
    it { expect(NotificationMailer).to have_received(:send_closed_notification).with(dossier) }
    it { expect(dossier.attestation).to eq(attestation) }
  end

  describe '#passer_en_instruction!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:operation_serialized) { JSON.parse(last_operation.serialized.download) }
    let(:gestionnaire) { create(:gestionnaire) }

    before { dossier.passer_en_instruction!(gestionnaire) }

    it { expect(dossier.state).to eq('en_instruction') }
    it { expect(dossier.followers_gestionnaires).to include(gestionnaire) }
    it { expect(last_operation.operation).to eq('passer_en_instruction') }
    it { expect(last_operation.automatic_operation?).to be_falsey }
    it { expect(operation_serialized['operation']).to eq('passer_en_instruction') }
    it { expect(operation_serialized['dossier_id']).to eq(dossier.id) }
    it { expect(operation_serialized['executed_at']).to eq(last_operation.executed_at.iso8601) }
  end

  describe '#passer_automatiquement_en_instruction!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:operation_serialized) { JSON.parse(last_operation.serialized.download) }
    let(:gestionnaire) { create(:gestionnaire) }

    before { dossier.passer_automatiquement_en_instruction! }

    it { expect(dossier.followers_gestionnaires).not_to include(gestionnaire) }
    it { expect(last_operation.operation).to eq('passer_en_instruction') }
    it { expect(last_operation.automatic_operation?).to be_truthy }
    it { expect(operation_serialized['operation']).to eq('passer_en_instruction') }
    it { expect(operation_serialized['dossier_id']).to eq(dossier.id) }
    it { expect(operation_serialized['executed_at']).to eq(last_operation.executed_at.iso8601) }
  end

  describe "#check_mandatory_champs" do
    let(:procedure) { create(:procedure, :with_type_de_champ) }
    let(:dossier) { create(:dossier, :with_all_champs, procedure: procedure) }

    it 'no mandatory champs' do
      expect(dossier.check_mandatory_champs).to be_empty
    end

    context "with mandatory champs" do
      let(:procedure) { create(:procedure, :with_type_de_champ_mandatory) }
      let(:champ_with_error) { dossier.champs.first }

      before do
        champ_with_error.value = nil
        champ_with_error.save
      end

      it 'should have errors' do
        errors = dossier.check_mandatory_champs
        expect(errors).not_to be_empty
        expect(errors.first).to eq("Le champ #{champ_with_error.libelle} doit être rempli.")
      end
    end

    context "with mandatory SIRET champ" do
      let(:type_de_champ) { create(:type_de_champ_siret, mandatory: true) }
      let(:champ_siret) { create(:champ_siret, type_de_champ: type_de_champ) }

      before do
        dossier.champs << champ_siret
      end

      it 'should not have errors' do
        errors = dossier.check_mandatory_champs
        expect(errors).to be_empty
      end

      context "and invalid SIRET" do
        before do
          champ_siret.update(value: "1234")
          dossier.reload
        end

        it 'should have errors' do
          errors = dossier.check_mandatory_champs
          expect(errors).not_to be_empty
          expect(errors.first).to eq("Le champ #{champ_siret.libelle} doit être rempli.")
        end
      end
    end

    context "with champ repetition" do
      let(:procedure) { create(:procedure) }
      let(:type_de_champ_repetition) { create(:type_de_champ_repetition, mandatory: true) }

      before do
        procedure.types_de_champ << type_de_champ_repetition
        type_de_champ_repetition.types_de_champ << create(:type_de_champ_text, mandatory: true)
      end

      context "when no champs" do
        let(:champ_with_error) { dossier.champs.first }

        it 'should have errors' do
          errors = dossier.check_mandatory_champs
          expect(errors).not_to be_empty
          expect(errors.first).to eq("Le champ #{champ_with_error.libelle} doit être rempli.")
        end
      end

      context "when mandatory champ inside repetition" do
        let(:champ_with_error) { dossier.champs.first.champs.first }

        before do
          dossier.champs.first.add_row
        end

        it 'should have errors' do
          errors = dossier.check_mandatory_champs
          expect(errors).not_to be_empty
          expect(errors.first).to eq("Le champ #{champ_with_error.libelle} doit être rempli.")
        end
      end
    end
  end

  describe '#hide!' do
    let(:dossier) { create(:dossier) }
    let(:administration) { create(:administration) }
    let(:last_operation) { dossier.dossier_operation_logs.last }

    before do
      Timecop.freeze
      dossier.hide!(administration)
    end

    after { Timecop.return }

    it { expect(dossier.hidden_at).to eq(Time.zone.now) }
    it { expect(last_operation.operation).to eq('supprimer') }
    it { expect(last_operation.automatic_operation?).to be_falsey }
  end

  describe '#repasser_en_instruction!' do
    let(:dossier) { create(:dossier, :refuse, :with_attestation) }
    let!(:gestionnaire) { create(:gestionnaire) }
    let(:last_operation) { dossier.dossier_operation_logs.last }

    before do
      Timecop.freeze
      allow(DossierMailer).to receive(:notify_revert_to_instruction)
        .and_return(double(deliver_later: true))
      dossier.repasser_en_instruction!(gestionnaire)
      dossier.reload
    end

    it { expect(dossier.state).to eq('en_instruction') }
    it { expect(dossier.processed_at).to be_nil }
    it { expect(dossier.motivation).to be_nil }
    it { expect(dossier.attestation).to be_nil }
    it { expect(last_operation.operation).to eq('repasser_en_instruction') }
    it { expect(JSON.parse(last_operation.serialized.download)['author']['email']).to eq(gestionnaire.email) }
    it { expect(DossierMailer).to have_received(:notify_revert_to_instruction).with(dossier) }

    after { Timecop.return }
  end
end
