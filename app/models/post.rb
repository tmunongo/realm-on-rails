class Post
  include ActiveModel::Model # Provides initializers, attributes, etc.
  include ActiveModel::Attributes

  # Attributes from Frontmatter
  attribute :title, :string
  attribute :description, :string
  attribute :publish_date, :date
  attribute :tags, :string
  attribute :series, :string
  attribute :cover_image_src, :string
  attribute :cover_image_alt, :string
  attribute :early_access, :boolean, default: false

  # File-based attributes
  attribute :slug, :string
  attribute :file_path, :string
  attribute :content_md, :string # Raw markdown body
  attribute :content_html, :string # Rendered HTML

  # Calculated attributes (placeholders for now)
  attribute :minutes_read, :integer
  attribute :read_time_text, :string
  attribute :view_count, :integer, default: 0

  # Add methods to find/load posts later
  # e.g., self.find(year, month, slug), self.all, self.recent(n)
end
