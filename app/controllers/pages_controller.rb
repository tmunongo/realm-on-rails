class PagesController < ApplicationController
  def home
    @postLoaderService = PostLoaderService.new("posts")

    @all_posts = @postLoaderService.load_all
    @recent_posts = @all_posts.take(5)
    @series = @all_posts.map(&:series).compact.uniq
  end

  def about; end

  def recommended_reading; end
end
