module IconHelper
  # Inline Lucide SVGs from app/assets/images. Usage: <%= icon("chart-pie", class: "w-4 h-4") %>
  def icon(name, css: "w-4 h-4 shrink-0", **attrs)
    path = Rails.root.join("app/assets/images/#{name}.svg")
    return "" unless File.exist?(path)

    svg = File.read(path)
    # Inject/merge class + attrs into the <svg> tag
    svg.sub("<svg", "<svg class=\"#{ERB::Util.html_escape(css)}\" aria-hidden=\"true\" #{tag_attrs(attrs)}")
       .html_safe
  end

  private
    def tag_attrs(attrs)
      attrs.map { |k, v| "#{k.to_s.dasherize}=\"#{ERB::Util.html_escape(v)}\"" }.join(" ")
    end
end
