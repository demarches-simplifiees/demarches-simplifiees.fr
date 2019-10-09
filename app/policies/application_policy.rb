class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class ApplicationScope
    attr_reader :user, :instructeur, :administrateur, :scope

    def initialize(account, scope)
      @user = account[:user]
      @instructeur = account[:instructeur]
      @administrateur = account[:administrateur]
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
