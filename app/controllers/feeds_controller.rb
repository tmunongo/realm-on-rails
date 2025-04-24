class FeedsController < ApplicationController
  def rss
    @postLoaderService = PostLoaderService.new
    @posts = @postLoaderService.load_all
    @posts = @posts.select { |post| post.publish_date <= Date.today }
    @posts = @posts.select { |post| post.early_access == false }

    render content_type: "application/rss+xml"
  end
end
