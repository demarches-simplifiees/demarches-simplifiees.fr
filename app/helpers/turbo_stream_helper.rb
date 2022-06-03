module TurboStreamHelper
  def turbo_stream
    TagBuilder.new(self)
  end

  class TagBuilder < Turbo::Streams::TagBuilder
    def dispatch(type, detail)
      append_all('turbo-events', partial: 'layouts/turbo_event', locals: { type: type, detail: detail })
    end

    def show(target, delay: nil)
      dispatch('dom:mutation', { action: :show, target: target, delay: delay }.compact)
    end

    def show_all(targets, delay: nil)
      dispatch('dom:mutation', { action: :show, targets: targets, delay: delay }.compact)
    end

    def hide(target, delay: nil)
      dispatch('dom:mutation', { action: :hide, target: target, delay: delay }.compact)
    end

    def hide_all(targets, delay: nil)
      dispatch('dom:mutation', { action: :hide, targets: targets, delay: delay }.compact)
    end

    def focus(target)
      dispatch('dom:mutation', { action: :focus, target: target })
    end

    def focus_all(targets)
      dispatch('dom:mutation', { action: :focus, targets: targets })
    end

    def disable(target)
      dispatch('dom:mutation', { action: :disable, target: target })
    end

    def enable(target)
      dispatch('dom:mutation', { action: :enable, target: target })
    end
  end
end
