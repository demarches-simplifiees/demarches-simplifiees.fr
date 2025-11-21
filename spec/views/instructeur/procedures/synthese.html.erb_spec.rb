# frozen_string_literal: true

describe 'instructeurs/procedures/synthese', type: :view do
  before do
    counters = InstructeursProceduresCountersService::Result.new(
      all_dossiers_counts: { "a-suivre" => 2, "suivis" => 0, "traites" => 1, "tous" => 3 },
      dossiers_count_per_procedure: {},
      dossiers_a_suivre_count_per_procedure: {},
      dossiers_termines_count_per_procedure: {},
      dossiers_expirant_count_per_procedure: {},
      followed_dossiers_count_per_procedure: {},
      groupes_instructeurs_ids: [12]
    )

    assign(:counters, counters)
  end

  subject do
    render
  end

  it do
    is_expected.to match(/2.+à suivre/m)
    is_expected.not_to have_text('suivis par moi')
    is_expected.to match(/1.+traité/m)
    is_expected.to match(/3.+au total/m)
  end
end
