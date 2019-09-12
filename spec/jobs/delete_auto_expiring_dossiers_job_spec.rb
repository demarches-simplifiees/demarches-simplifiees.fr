require 'rails_helper'

RSpec.describe DeleteAutoExpiringDossiersJob , type: :job do
  let!(:state) { nil }

  let!(:date_hidden) { Date.today - 2.months}
  let!(:date_near_expiring) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 1.months}
  let!(:date_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months - 6.days}
  let!(:date_not_expired) { Date.today - procedure.duree_conservation_dossiers_dans_ds.months + 2.months  }
  let!(:procedure) { create(:procedure, :with_instructeur, declarative_with_state: state) }

  context "Suppression automatique des dossiers : " do
    let!(:nouveau_hidden_dossier1) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:brouillon), hidden_at: date_hidden) }
    let!(:nouveau_hidden_dossier2) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), hidden_at: date_hidden) }

    let!(:nouveau_brouillon_dossier1) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure, created_at: date_expired)} #expiré
    let!(:nouveau_brouillon_dossier2) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure, created_at: date_near_expiring) } #expirant
    let!(:nouveau_brouillon_dossier3) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure, created_at: date_not_expired) } #autre

    let!(:nouveau_construction_dossier1) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at:date_expired) } #expiré
    let!(:nouveau_construction_dossier2) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at:date_near_expiring) } #expirant
    let!(:nouveau_construction_dossier3) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure, en_construction_at: date_not_expired) } #autre

    let!(:nouveau_instruction_dossier1) { create(:dossier, state: Dossier.states.fetch(:en_instruction), procedure: procedure, en_instruction_at:date_expired) } #expiré
    let!(:nouveau_instruction_dossier2) { create(:dossier, state: Dossier.states.fetch(:en_instruction), procedure: procedure, en_instruction_at:date_near_expiring) } #expirant
    let!(:nouveau_instruction_dossier3) { create(:dossier, state: Dossier.states.fetch(:en_instruction), procedure: procedure, en_instruction_at:date_not_expired) } #autre

    before do
      allow(DossierMailer).to receive(:notify_excuse_deletion_to_user).and_return(double(deliver_later: nil))
      allow(DossierMailer).to receive(:notify_auto_deletion_to).and_return(double(deliver_later: nil))
      allow(DossierMailer).to receive(:notify_near_deletion).and_return(double(deliver_later: nil))
      DeleteAutoExpiringDossiersJob.new.perform
    end

    it 'Verification de la presence des dossiers non expirés' do
      nouveau_brouillon_dossier2.reload
      nouveau_brouillon_dossier3.reload
      nouveau_construction_dossier2.reload
      nouveau_construction_dossier3.reload
      nouveau_instruction_dossier2.reload
      nouveau_instruction_dossier3.reload
    end

    it 'Verification de la suppression des dossiers expirés' do
      expect { nouveau_hidden_dossier1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { nouveau_hidden_dossier2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { nouveau_brouillon_dossier1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { nouveau_construction_dossier1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { nouveau_instruction_dossier1.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'verification de la creation de mail' do
      expect(DossierMailer).to have_received(:notify_excuse_deletion_to_user).twice
      expect(DossierMailer).to have_received(:notify_excuse_deletion_to_user).with([nouveau_construction_dossier1], nouveau_construction_dossier1.user.email)
      expect(DossierMailer).to have_received(:notify_excuse_deletion_to_user).with([nouveau_instruction_dossier1], nouveau_instruction_dossier1.user.email)

      expect(DossierMailer).to have_received(:notify_auto_deletion_to).twice
      expect(DossierMailer).to have_received(:notify_auto_deletion_to).with([nouveau_brouillon_dossier1], nouveau_brouillon_dossier1.user.email)
      expect(DossierMailer).to have_received(:notify_auto_deletion_to).with([nouveau_construction_dossier1, nouveau_instruction_dossier1], procedure.administrateurs.pluck(:email)[0])

      expect(DossierMailer).to have_received(:notify_near_deletion).twice
      expect(DossierMailer).to have_received(:notify_near_deletion).with(["#{ nouveau_brouillon_dossier2.id} qui concerne la procedure '#{procedure.libelle}', doit être déposé avant le #{Date.today + 1.months} 00:00:00 +0200, sinon il sera supprimé"], nouveau_brouillon_dossier2.user.email)
      expect(DossierMailer).to have_received(:notify_near_deletion).with(["#{ nouveau_construction_dossier2.id} qui concerne la procedure '#{procedure.libelle}', doit être traité avant le #{Date.today + 1.months} 00:00:00 +0200",
                                                                          "#{ nouveau_instruction_dossier2.id} qui concerne la procedure '#{procedure.libelle}', doit être traité avant le #{Date.today + 1.months} 00:00:00 +0200"], procedure.administrateurs.pluck(:email)[0])
    end
  end

  after { Timecop.return }
end
