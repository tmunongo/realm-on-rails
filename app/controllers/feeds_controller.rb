class FeedsController < ApplicationController
  def rss
    @posts = PostLoaderService.load_all
    @posts = @posts.select { |post| post.publish_date <= Date.today }
    @posts = @posts.select { |post| post.early_access == false }

    respond_to do |format|
      format.xml { render content_type: "application/rss+xml" }
    end
  end
end
