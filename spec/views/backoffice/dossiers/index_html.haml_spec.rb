require 'spec_helper'

describe 'backoffice/dossiers/index.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  let!(:procedure) { create(:procedure, :published, administrateur: administrateur) }

  let!(:decorate_dossier_en_construction) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction').decorate }
  let!(:decorate_dossier_en_instruction) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_instruction').decorate }
  let!(:decorate_dossier_accepte) { create(:dossier, :with_entreprise, procedure: procedure, state: 'accepte').decorate }
  let!(:decorate_dossier_refused) { create(:dossier, :with_entreprise, procedure: procedure, state: 'refused').decorate }
  let!(:decorate_dossier_without_continuation) { create(:dossier, :with_entreprise, procedure: procedure, state: 'without_continuation').decorate }

  let(:dossiers_list_facade) { DossiersListFacades.new gestionnaire, nil }

  let(:new_dossiers_list) { dossiers_list_facade.service.nouveaux }
  let(:follow_dossiers_list) { dossiers_list_facade.service.suivi }
  let(:all_state_dossiers_list) { dossiers_list_facade.service.all_state }

  before do
    decorate_dossier_en_instruction.entreprise.update_column(:raison_sociale, 'plup')
    decorate_dossier_accepte.entreprise.update_column(:raison_sociale, 'plyp')
    decorate_dossier_refused.entreprise.update_column(:raison_sociale, 'plzp')
    decorate_dossier_without_continuation.entreprise.update_column(:raison_sociale, 'plnp')

    create :preference_list_dossier,
      gestionnaire: gestionnaire,
      table: nil,
      attr: 'state',
      attr_decorate: 'display_state'

    create :preference_list_dossier,
      gestionnaire: gestionnaire,
      table: 'procedure',
      attr: 'libelle',
      attr_decorate: 'libelle'

    create :preference_list_dossier,
      gestionnaire: gestionnaire,
      table: 'entreprise',
      attr: 'raison_sociale',
      attr_decorate: 'raison_sociale'

    create :preference_list_dossier,
      gestionnaire: gestionnaire,
      table: nil,
      attr: 'last_update',
      attr_decorate: 'last_update'

    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    sign_in gestionnaire

    assign :facade_data_view, dossiers_list_facade

    assign(:new_dossiers, (smart_listing_create :new_dossiers,
      new_dossiers_list,
      partial: "backoffice/dossiers/list",
      array: true))

    assign(:follow_dossiers, (smart_listing_create :follow_dossiers,
      follow_dossiers_list,
      partial: "backoffice/dossiers/list",
      array: true))

    assign(:all_state_dossiers, (smart_listing_create :all_state_dossiers,
      all_state_dossiers_list,
      partial: "backoffice/dossiers/list",
      array: true))

    render
  end

  subject { rendered }

  it { is_expected.to have_content('Nouveaux dossiers 1 dossier') }
  it { is_expected.to have_content('Dossiers suivis 0 dossiers') }
  it { is_expected.to have_content('Tous les dossiers 5 dossiers') }

  it { is_expected.to have_content('État') }
  it { is_expected.to have_content('Libellé procédure') }
  it { is_expected.to have_content('Raison sociale') }
  it { is_expected.to have_content('Mise à jour le') }

  it { is_expected.to have_content('plup') }
  it { is_expected.to have_content('plyp') }
end
