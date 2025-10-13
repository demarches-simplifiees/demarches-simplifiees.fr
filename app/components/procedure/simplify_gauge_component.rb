class Procedure::SimplifyGaugeComponent < ApplicationComponent
  def initialize(procedure, revision)
    @linter = ProcedureLinter.new(procedure, revision)
  end

  def call
    safe_join([
      tag.div(id: 'password_hint', class: "password-complexity complexity-#{@linter.rate / 2 - 1}"),
      tag.strong(class: 'text-center fr-hint-text') { @linter.quali_score }
    ])
  end
end
