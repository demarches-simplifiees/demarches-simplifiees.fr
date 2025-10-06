# frozen_string_literal: true

describe 'instructeurs/procedures/synthese', type: :view do
  before do
    assign(:all_dossiers_counts, { "a-suivre" => 2, "suivis" => 0, "traites" => 1, "tous" => 3 })
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
