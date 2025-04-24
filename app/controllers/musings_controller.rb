class MusingsController < ApplicationController
    POSTS_PER_PAGE = 5

  def index
    @postLoaderService = PostLoaderService.new("musings")
    all_posts = @postLoaderService.load_all
    @pagy, @posts = pagy_array(all_posts, items: POSTS_PER_PAGE)
    @posts_by_year = @posts.group_by { |post| post.publish_date.year }
  end

  def show
    year = params[:year]
    month = params[:month]
    slug = params[:slug]
    @postLoaderService = PostLoaderService.new("musings")
    @post = @postLoaderService.find(year, month, slug)

    if @post.nil?
      # Handle post not found (e.g., render 404)
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
      nil
    end

    # Basic view tracking placeholder (implement properly later)
    # track_view(@post, request.remote_ip)
  end
end
