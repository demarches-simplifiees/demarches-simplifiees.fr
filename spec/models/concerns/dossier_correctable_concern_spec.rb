# frozen_string_literal: true

describe DossierCorrectableConcern do
  describe "#pending_correction?" do
    let(:dossier) { create(:dossier, :en_construction) }

    context "when dossier has no correction" do
      it { expect(dossier.pending_correction?).to be_falsey }
    end

    context "when dossier has a pending correction" do
      before { create(:dossier_correction, dossier:) }

      it { expect(dossier.pending_correction?).to be_truthy }
    end

    context "when dossier has a resolved correction" do
      before { create(:dossier_correction, :resolved, dossier:) }

      it { expect(dossier.pending_correction?).to be_falsey }
    end

    context "when dossier is not en_construction" do
      let(:dossier) { create(:dossier, :en_instruction) }
      before { create(:dossier_correction, dossier:) }

      it { expect(dossier.pending_correction?).to be_falsey }
    end
  end

  describe '#flag_as_pending_correction!' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:instructeur) { create(:instructeur) }
    let(:commentaire) { create(:commentaire, dossier:, instructeur:) }

    subject(:flag) { dossier.flag_as_pending_correction!(commentaire) }

    context 'when dossier is en_construction' do
      it 'creates a correction' do
        expect { flag }.to change { dossier.corrections.pending.count }.by(1)
        expect(dossier.corrections.last).to be_dossier_incorrect
      end

      it 'created a correction of incomplete kind' do
        expect { dossier.flag_as_pending_correction!(commentaire, "incomplete") }.to change { dossier.corrections.pending.count }.by(1)
        expect(dossier.corrections.last).to be_dossier_incomplete
      end

      it 'does not change dossier state' do
        expect { flag }.not_to change { dossier.state }
      end
    end

    context 'when dossier is en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it 'creates a correction' do
        expect { flag }.to change { dossier.corrections.pending.count }.by(1)
      end

      it 'repasse dossier en_construction' do
        expect { flag }.to change { dossier.state }.to('en_construction')
      end
    end

    context 'when dossier has already a pending correction' do
      before { create(:dossier_correction, dossier:) }

      it 'does not create a correction' do
        expect { flag }.not_to change { dossier.corrections.pending.count }
      end
    end

    context 'when dossier has already a resolved correction' do
      before { create(:dossier_correction, :resolved, dossier:) }

      it 'creates a correction' do
        expect { flag }.to change { dossier.corrections.pending.count }.by(1)
      end
    end

    context 'when dossier is not en_construction and may not be repassed en_construction' do
      let(:dossier) { create(:dossier, :accepte) }

      it 'does not create a correction' do
        expect { flag }.not_to change { dossier.corrections.pending.count }
      end
    end

    context 'when procedure is sva' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: create(:procedure, :published, :sva)) }

      it 'creates a correction' do
        expect { flag }.to change { dossier.corrections.pending.count }.by(1)
      end

      it 'repasse dossier en_construction' do
        expect { flag }.to change { dossier.state }.to('en_construction')
      end

      it 'creates a log operation' do
        expect { flag }.to change { dossier.dossier_operation_logs.count }.by(2)

        correction_log = dossier.dossier_operation_logs.find { |log| log.operation == "demander_une_correction" }
        construction_log = dossier.dossier_operation_logs.find { |log| log.operation == "repasser_en_construction" }

        expect(correction_log).to be_present
        expect(construction_log).to be_present
        expect(correction_log.data["subject"]["body"]).to eq(commentaire.body)
        expect(correction_log.data["subject"]["email"]).to eq(commentaire.instructeur.email)
      end

      it 'creates a log operation of incomplete dossier' do
        expect { dossier.flag_as_pending_correction!(commentaire, "incomplete") }.to change { dossier.dossier_operation_logs.count }.by(2)

        correction_log = dossier.dossier_operation_logs.find { |log| log.operation == "demander_a_completer" }
        construction_log = dossier.dossier_operation_logs.find { |log| log.operation == "repasser_en_construction" }

        expect(correction_log).to be_present
        expect(construction_log).to be_present
        expect(correction_log.data["subject"]["body"]).to eq(commentaire.body)
        expect(correction_log.data["subject"]["email"]).to eq(commentaire.instructeur.email)
      end
    end

    context "when there are instructeurs followers" do
      let!(:instructeur_follower) { create(:instructeur) }
      let!(:instructeur_not_follower) { create(:instructeur) }
      let!(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur_follower, instructeur_not_follower]) }

      before do
        dossier.assign_to_groupe_instructeur(groupe_instructeur, DossierAssignment.modes.fetch(:auto))
        instructeur_follower.followed_dossiers << dossier
      end

      it "create attente_correction notification only for instructeur follower" do
        expect { subject }.to change(DossierNotification, :count).by(1)

        notification = DossierNotification.last
        expect(notification.dossier_id).to eq(dossier.id)
        expect(notification.instructeur_id).to eq(instructeur_follower.id)
        expect(notification.notification_type).to eq("attente_correction")
      end
    end
  end

  describe "#resolve_pending_correction!" do
    let(:dossier) { create(:dossier, :en_construction) }

    subject(:resolve) { dossier.resolve_pending_correction! }

    context "when dossier has no correction" do
      it { expect { resolve }.not_to change { dossier.corrections.pending.count } }
    end

    context "when dossier has a pending correction" do
      let!(:correction) { create(:dossier_correction, dossier:) }

      it {
        expect { resolve }.to change { correction.reload.resolved_at }.from(nil)
      }
    end

    context "when dossier has attente_correction notification" do
      let!(:correction) { create(:dossier_correction, dossier:) }
      let!(:instructeur) { create(:instructeur) }
      let!(:notification) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:, notification_type: :attente_correction) }

      it "destroy notification for all instructeurs" do
        subject

        expect(DossierNotification.exists?(notification.id)).to be_falsey
      end
    end

    context "when dossier has a already resolved correction" do
      before { create(:dossier_correction, :resolved, dossier:) }

      it { expect { resolve }.not_to change { dossier.corrections.pending.count } }
    end
  end
end
