# app/services/post_loader_service.rb
require 'front_matter_parser'
require 'redcarpet'

class PostLoaderService
  POSTS_PATH = Rails.root.join('content', 'posts')
  MARKDOWN_RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: false), # Basic HTML renderer
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    superscript: true,
    underline: true,
    highlight: true,
    quote: true,
    footnotes: true
    # Add more extensions as needed
  )

  def self.load_all
    # Ensure the posts directory exists
    return [] unless Dir.exist?(POSTS_PATH)

    # Find all markdown files recursively (for potential year/month folders)
    Dir.glob(POSTS_PATH.join('**', '*.md')).map do |file_path|
      load_from_file(file_path)
    end.compact.sort_by(&:publish_date).reverse # Sort newest first
  end

  def self.find(year, month, slug)
    # Construct expected path (adjust if your structure differs)
    file_path = POSTS_PATH.join(year, month, "#{slug}.md")
    return nil unless File.exist?(file_path)
    load_from_file(file_path.to_s)
  end

  private

  def self.load_from_file(file_path)
    begin
      parsed = FrontMatterParser::Parser.parse_file(file_path)
      front_matter = parsed.front_matter
      content_md = parsed.content

      # Extract slug from filename or path if needed (simple example)
      slug = File.basename(file_path, '.md')
      # Refine slug extraction based on your final path structure (e.g., from year/month/slug.md)

      # Create Post object
      Post.new(
        title: front_matter['title'],
        description: front_matter['description'],
        publish_date: front_matter['publishDate'] ? Date.parse(front_matter['publishDate'].to_s) : Date.today,
        tags: front_matter['tags']&.join(', '), # Simple comma-separated string for now
        series: front_matter['series'],
        cover_image_src: front_matter['coverImage']&.dig('src'),
        cover_image_alt: front_matter['coverImage']&.dig('alt'),
        early_access: front_matter['earlyAccess'] || false,
        slug: slug,
        file_path: file_path,
        content_md: content_md,
        content_html: MARKDOWN_RENDERER.render(content_md)
        # Placeholder for calculated fields
        # minutes_read: calculate_read_time(content_md),
        # read_time_text: "#{calculate_read_time(content_md)} min read"
      )
    rescue StandardError => e
      Rails.logger.error "Failed to load post from #{file_path}: #{e.message}"
      nil # Skip files that fail to parse
    end
  end

  # Placeholder - Implement read time calculation logic
  # def self.calculate_read_time(text)
  #   words_per_minute = 200
  #   words = text.split.size
  #   (words / words_per_minute.to_f).ceil
  # end
end