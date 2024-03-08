class ProcedureRevisionChange
  attr_reader :type_de_champ
  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def label = @type_de_champ.libelle
  def stable_id = @type_de_champ.stable_id
  def private? = @type_de_champ.private?
  def child? = @type_de_champ.child?

  def to_h = { op:, stable_id:, label:, private: private? }

  class AddChamp < ProcedureRevisionChange
    def initialize(type_de_champ)
      super(type_de_champ)
    end

    def op = :add
    def mandatory? = @type_de_champ.mandatory?
    def can_rebase?(dossier = nil) = !mandatory?

    def to_h = super.merge(mandatory: mandatory?)
  end

  class RemoveChamp < ProcedureRevisionChange
    def initialize(type_de_champ)
      super(type_de_champ)
    end

    def op = :remove
    def can_rebase?(dossier = nil) = true
  end

  class MoveChamp < ProcedureRevisionChange
    attr_reader :from, :to

    def initialize(type_de_champ, from, to)
      super(type_de_champ)
      @from = from
      @to = to
    end

    def op = :move
    def can_rebase?(dossier = nil) = true
    def to_h = super.merge(from:, to:)
  end

  class UpdateChamp < ProcedureRevisionChange
    attr_reader :attribute, :from, :to

    def initialize(type_de_champ, attribute, from, to)
      super(type_de_champ)
      @attribute = attribute
      @from = from
      @to = to
    end

    def op = :update
    def to_h = super.merge(attribute:, from:, to:)

    def can_rebase?(dossier = nil)
      return true if private?
      case attribute
      when :drop_down_options
        (from - to).empty? || dossier&.can_rebase_drop_down_options_change?(stable_id, from - to)
      when :drop_down_other
        !from && to
      when :mandatory
        (from && !to) || dossier&.can_rebase_mandatory_change?(stable_id)
      when :type_champ, :condition, :expression_reguliere
        false
      else
        true
      end
    end
  end
end
