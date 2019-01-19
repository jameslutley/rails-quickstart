module ApplicationHelper
  def tailwind_class_for(flash_type)
    {
      success: "alert-success",
      error: "alert-danger",
      alert: "alert-warning",
      notice: "alert-info"
    }.stringify_keys[flash_type.to_s] || flash_type.to_s
  end

  def markdown(content)
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, escape_html: true)
    options = {
      autolink: true,
      disable_indented_code_blocks: true,
      fenced_code_blocks: true,
      footnotes: true,
      lax_html_blocks: true,
      no_intra_emphasis: true,
      space_after_headers: true,
      strikethrough: true,
      superscript: true,
      tables: true,
      underline: true
    }
    Redcarpet::Markdown.new(renderer, options).render(content).html_safe
  end
end
