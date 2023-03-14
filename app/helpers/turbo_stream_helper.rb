module TurboStreamHelper
  def turbo_stream
    TagBuilder.new(self)
  end

  class TagBuilder < Turbo::Streams::TagBuilder
    include ActionView::Helpers::TagHelper

    def show(target, delay: nil)
      turbo_stream_simple_action_tag :show, target: target, delay: delay
    end

    def show_all(targets, delay: nil)
      turbo_stream_simple_action_tag :show, targets: targets, delay: delay
    end

    def hide(target, delay: nil)
      turbo_stream_simple_action_tag :hide, target: target, delay: delay
    end

    def hide_all(targets, delay: nil)
      turbo_stream_simple_action_tag :hide, targets: targets, delay: delay
    end

    def focus(target)
      turbo_stream_simple_action_tag :focus, target: target
    end

    def focus_all(targets)
      turbo_stream_simple_action_tag :focus, targets: targets
    end

    def enable(target)
      turbo_stream_simple_action_tag :enable, target: target
    end

    def enable_all(targets)
      turbo_stream_simple_action_tag :enable, targets: targets
    end

    def disable(target)
      turbo_stream_simple_action_tag :disable, target: target
    end

    def disable_all(targets)
      turbo_stream_simple_action_tag :disable, targets: targets
    end

    def morph(target, content = nil, **rendering, &block)
      action :morph, target, content, **rendering, &block
    end

    def morph_all(targets, content = nil, **rendering, &block)
      action_all :morph, targets, content, **rendering, &block
    end

    def dispatch(type, detail = {})
      turbo_stream_simple_action_tag(:dispatch, 'event-type': type, 'event-detail': detail.to_json)
    end

    private

    def turbo_stream_simple_action_tag(action, target: nil, targets: nil, **attributes)
      if (target = convert_to_turbo_stream_dom_id(target))
        tag.turbo_stream('', **attributes.merge(action: action, target: target))
      elsif (targets = convert_to_turbo_stream_dom_id(targets, include_selector: true))
        tag.turbo_stream('', **attributes.merge(action: action, targets: targets))
      else
        tag.turbo_stream('', **attributes.merge(action: action))
      end
    end
  end
end
