describe Administrateurs::TransitionsRulesController, type: :controller do
  include Logic
  let(:user) { create(:user) }
  let(:admin) { create(:administrateur, user: create(:user)) }
  let(:procedure) { create(:procedure, administrateurs: [admin], types_de_champ_public:) }
  let(:types_de_champ_public) { [] }

  describe 'condition management' do
    before { sign_in(admin.user) }

    let(:types_de_champ_public) { [{type: :yes_no}]}
    let(:yes_no_tdc) { procedure.draft_revision.types_de_champ_public.first }
    let(:targeted_champ) { champ_value(yes_no_tdc.stable_id).to_json }
    let(:default_params) do
      {
        procedure_id: procedure.id,
        revision_id: procedure.draft_revision.id,
      }
    end

    describe '#change_targeted_champ' do
      let(:condition_form) do
        {
          rows: [
            {
              targeted_champ: targeted_champ,
              operator_name:  Logic::Eq.name,
              value: constant(true).to_json
            }
          ]
        }
      end
      subject { patch :change_targeted_champ, params: default_params.merge(procedure_revision: { condition_form: }), format: :turbo_stream }
      it 'update condition' do
        expect { subject }.to change { procedure.draft_revision.reload.transitions_rules }
          .from(nil)
          .to(ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)))
      end
    end

    describe '#update' do
      let(:value) { constant(true).to_json }
      let(:operator_name) { Logic::Eq.name }
      let(:condition_form) do
        {
          rows: [
            {
              targeted_champ: targeted_champ,
              operator_name: operator_name,
              value: value
            }
          ]
        }
      end
      subject { patch :update, params: default_params.merge(procedure_revision: { condition_form: condition_form }), format: :turbo_stream }
      it 'updates condition' do
        expect { subject }.to change { procedure.draft_revision.reload.transitions_rules }
          .from(nil)
          .to(ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)))
      end
    end

    describe '#add_row' do
      subject { post :add_row, params: default_params, format: :turbo_stream }

      context 'without any row' do
        it 'creates an empty condition' do
          expect { subject }.to change { procedure.draft_revision.reload.transitions_rules }
            .from(nil)
            .to(empty_operator(empty, empty))
        end
      end

      context 'with row' do
        before do
          procedure.draft_revision.transitions_rules = ds_eq(champ_value(yes_no_tdc.stable_id), constant(true))
          procedure.draft_revision.save!
        end

        it 'add one more creates an empty condition' do
          expect { subject }.to change { procedure.draft_revision.reload.transitions_rules }
            .from(ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)))
            .to(ds_and([
              ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)),
              empty_operator(empty, empty)
            ]))
        end
      end
    end

    describe 'delete_row' do
      let(:condition_form) do
        {
          top_operator_name: Logic::And.name,
          rows: [
            {
              targeted_champ: targeted_champ,
              operator_name:  Logic::Eq.name,
              value: constant(true).to_json
            },
            {
              targeted_champ: targeted_champ,
              operator_name:  Logic::Eq.name,
              value: constant(false).to_json
            }
          ]
        }
      end
      let(:initial_condition) do
        ds_and([
          ds_eq(champ_value(yes_no_tdc.stable_id), constant(true)),
          ds_eq(champ_value(yes_no_tdc.stable_id), constant(false))
        ])
      end

      subject { delete :delete_row, params: default_params.merge(row_index: 0, procedure_revision: { condition_form: }), format: :turbo_stream }
      it 'remove condition' do
        procedure.draft_revision.update(transitions_rules: initial_condition)

        expect { subject }
          .to change { procedure.draft_revision.reload.transitions_rules }
          .from(initial_condition)
          .to(ds_eq(champ_value(yes_no_tdc.stable_id), constant(false)))
      end
    end
  end

  describe '#edit' do
    subject { get :edit, params: { procedure_id: procedure.id } }

    context 'when user is not signed in' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when user is signed in but not admin of procedure' do
      before { sign_in(user) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when user is signed as admin' do
      before do
        sign_in(admin.user)
        subject
      end

      it { is_expected.to have_http_status(200) }

      context 'rendered without tdc' do
        let(:types_de_champ_public) { [] }
        render_views

        it { expect(response.body).to have_link("Ajouter un champ supportant le conditionnel") }
      end

      context 'rendered with tdc' do
        let(:types_de_champ_public) { [{ type: :yes_no }] }
        render_views

        it { expect(response.body).not_to have_link("Ajouter un champ supportant le conditionnel") }
      end
    end
  end
end
