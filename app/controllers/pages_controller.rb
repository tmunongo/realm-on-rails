class PagesController < ApplicationController
  def home
    @all_posts = PostLoaderService.load_all # Consider caching this
    @recent_posts = @all_posts.take(5)
    @series = @all_posts.map(&:series).compact.uniq
  end

  def about
  end
end
