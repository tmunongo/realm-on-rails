# We define a module that can parse markdown to HTML with its `call` method
module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template, source)
    compiled_source = erb.call(template, source)
    "Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), tables: true, fenced_code_blocks: true, autolink: true, strikethrough: true, superscript: true).render((#{compiled_source};).to_s).html_safe"
  end
end

# Now we tell Rails to process any files with the `.md` extension using our new MarkdownHandler
ActionView::Template.register_template_handler :md, MarkdownHandler