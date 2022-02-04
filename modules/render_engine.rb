module RenderEngine
  LAYOUT_PATH = '/layout'.freeze

  def render(page, status = 200)
    Rack::Response.new(render_template(LAYOUT_PATH) { render_template(page) }, status)
  end

  def render_template(page)
    path = File.expand_path("../views#{page}.html.haml", __dir__)
    Haml::Engine.new(File.read(path)).render(binding)
  end

  def redirect(target)
    Rack::Response.new { |response| response.redirect(target) }
  end
end
