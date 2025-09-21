class Procedure::SimplifyGaugeComponent < ApplicationComponent
  def initialize(procedure, revision)
    @linter = ProcedureLinter.new(procedure, revision)
  end

  def call
    safe_join([
      tag.div(id: 'password_hint', class: "password-complexity complexity-#{@linter.rate / 2 - 1}"),
      tag.h3(class: 'text-center fr-alert__title') { @linter.quali_score }
    ])
  end
end
