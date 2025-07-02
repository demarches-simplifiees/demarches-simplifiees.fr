# frozen_string_literal: true

describe 'users/dossiers/show_deleted', type: :view do
  let(:procedure) { create(:procedure, :published, libelle: 'Test Procedure') }
  let(:user) { create(:user) }
  let(:deleted_dossier) do
    DeletedDossier.create!(
      dossier_id: 275,
      user_id: user.id,
      procedure_id: procedure.id,
      state: 'en_construction',
      reason: 'user_request',
      deleted_at: Time.current,
      depose_at: Date.current,
      groupe_instructeur_id: 1,
      revision_id: 1
    )
  end

  before do
    sign_in user
    assign(:deleted_dossier, deleted_dossier)
  end

  subject! { render }

  it 'renders the deleted dossier page' do
    expect(rendered).to have_text("Le dossier n° #{deleted_dossier.dossier_id} a été supprimé")
    expect(rendered).to have_text('Vous ne pouvez plus récupérer ce dossier')
  end

  it 'includes the correct card structure' do
    expect(rendered).to have_css('.fr-card.fr-card--no-border')
  end

  it 'displays the dossier ID' do
    expect(rendered).to have_text(deleted_dossier.dossier_id.to_s)
  end

  it 'shows the list of deletion reasons' do
    expect(rendered).to have_text('pour une des raisons suivantes')
    expect(rendered).to have_text('Il a été mis à la corbeille à votre demande')
    expect(rendered).to have_text('Il a été supprimé car son délai maximal')
  end

  it 'has a link to the deleted dossiers history' do
    expect(rendered).to have_text('Historique des dossiers supprimés')
  end

  it 'displays the explanation text' do
    expect(rendered).to have_text('Vous ne pouvez plus récupérer ce dossier pour une des raisons suivantes')
  end

  context 'with different deletion reasons' do
    shared_examples 'shows correct reason text' do |reason|
      before do
        deleted_dossier.update(reason: reason)
        assign(:deleted_dossier, deleted_dossier.reload)
      end

      subject! { render }

      it "shows #{reason} deletion reasons" do
        expect(rendered).to have_text('Il a été mis à la corbeille à votre demande')
        expect(rendered).to have_text('Il a été supprimé car son délai maximal')
      end
    end

    include_examples 'shows correct reason text', 'user_request'
    include_examples 'shows correct reason text', 'expired'
    include_examples 'shows correct reason text', 'user_removed'
  end

  context 'when deleted dossier has specific ID' do
    let(:deleted_dossier) do
      DeletedDossier.create!(
        dossier_id: 99999,
        user_id: user.id,
        procedure_id: procedure.id,
        state: 'en_construction',
        reason: 'user_request',
        deleted_at: Time.current,
        depose_at: Date.current,
        groupe_instructeur_id: 1,
        revision_id: 1
      )
    end

    it 'displays the correct dossier ID' do
      expect(rendered).to have_text('Le dossier n° 99999 a été supprimé')
    end
  end
end
