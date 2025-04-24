# app/services/post_loader_service.rb
require "front_matter_parser"
require "redcarpet"

class PostLoaderService
  def initialize(content_type = "posts")
    @content_type = content_type
    @posts_path = Rails.root.join("content", @content_type)
  end

  def self.posts_path
    Rails.root.join("content", @@content_type)
  end

  MARKDOWN_RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: false),
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    superscript: true,
    underline: true,
    highlight: true,
    quote: true,
    footnotes: true,
  )

  def load_all
    return [] unless Dir.exist?(@posts_path)

    Dir.glob(@posts_path.join("**", "*.md")).map do |file_path|
      load_from_file(file_path)
    end.compact.sort_by(&:publish_date).reverse # Sort newest first
  end

  def find(year, month, slug)
    file_path = @posts_path.join(year, month, "#{slug}.md")
    return nil unless File.exist?(file_path)
    load_from_file(file_path.to_s)
  end

  private

  def load_from_file(file_path)
    begin
      parsed = FrontMatterParser::Parser.parse_file(file_path)
      front_matter = parsed.front_matter
      content_md = parsed.content

      slug = File.basename(file_path, ".md")

      # Create Post object
      Post.new(
        title: front_matter["title"],
        description: front_matter["description"],
        publish_date: front_matter["publishDate"] ? Date.parse(front_matter["publishDate"].to_s) : Date.today,
        tags: front_matter["tags"]&.join(", "),
        series: front_matter["series"],
        cover_image_src: front_matter["coverImage"]&.dig("src"),
        cover_image_alt: front_matter["coverImage"]&.dig("alt"),
        early_access: front_matter["earlyAccess"] || false,
        slug: slug,
        file_path: file_path,
        content_md: content_md,
        content_html: MARKDOWN_RENDERER.render(content_md),
        minutes_read: calculate_read_time(content_md),
        read_time_text: "#{calculate_read_time(content_md)} min read"
      )
    rescue StandardError => e
      Rails.logger.error "Failed to load post from #{file_path}: #{e.message}"
      nil
    end
  end

  def calculate_read_time(text)
    words_per_minute = 200
    words = text.split.size
    (words / words_per_minute.to_f).ceil
  end
end
