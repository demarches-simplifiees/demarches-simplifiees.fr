module MailTemplateConcern
  extend ActiveSupport::Concern
  include DocumentTemplateConcern

  def object_for_dossier(dossier)
    replace_tags(object, dossier)
  end

  def body_for_dossier(dossier)
    replace_tags(body, dossier)
  end

  def tags()
    super(for_closed_dossier: self.class.const_get(:IS_FOR_CLOSED_DOSSIER))
  end

  module ClassMethods
    def default_for(procedure)
      body = ActionController::Base.new.render_to_string(template: self.const_get(:TEMPLATE_NAME))
      self.new(object: self.const_get(:DEFAULT_OBJECT), body: body, procedure: procedure)
    end
  end

  private

  def replace_tags(string, dossier)
    super(string, dossier, for_closed_dossier: self.class.const_get(:IS_FOR_CLOSED_DOSSIER))
  end
end
