# frozen_string_literal: true

class ReactComponent < ApplicationComponent
  erb_template <<-ERB
    <% if content? %>
      <react-component name=<%= @name %> props="<%= @props.to_json %>"><%= content %></react-component>
    <% else %>
      <react-component name=<%= @name %> props="<%= @props.to_json %>"></react-component>
    <% end %>
  ERB

  def initialize(name, **props)
    @name = name
    @props = props
  end
end
