# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :load_all_posts, only: [:index]
  POSTS_PER_PAGE = 5

  def index
    all_posts = PostLoaderService.load_all
    @pagy, @posts = pagy_array(all_posts, items: POSTS_PER_PAGE)
    @posts_by_year = @posts.group_by { |post| post.publish_date.year }
  end

  def show
    year = params[:year]
    month = params[:month]
    slug = params[:slug]
    @post = PostLoaderService.find(year, month, slug)

    if @post.nil?
      # Handle post not found (e.g., render 404)
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
      return
    end

    # Basic view tracking placeholder (implement properly later)
    # track_view(@post, request.remote_ip)

    # Render the show template (app/views/posts/show.html.erb)
  end

  private

  def load_all_posts
     @posts = PostLoaderService.load_all # Definitely cache this
  end

  # Placeholder for view tracking
  # def track_view(post, ip_address)
  #   # Logic to increment view count, likely storing in a DB or cache
  #   # associated with post slug/path and potentially IP for uniqueness within a timeframe
  # end
end