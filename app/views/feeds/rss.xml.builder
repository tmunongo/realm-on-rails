# app/views/feeds/rss.xml.builder
# frozen_string_literal: true

channel_title = "Tawanda's Realm"
channel_link = root_url
channel_description = "A software engineer trying to find the place where technology, philosophy, and story-telling meet."
channel_language = "en-us"

# app/views/feeds/rss.xml.builder

xml.instruct! :xml, version: "1.0", encoding: "UTF-8" # Added encoding
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title @channel_title || "Tawanda's Realm"
    xml.link @channel_link || root_url
    xml.description @channel_description || "A software engineer trying to find the place where technology, philosophy, and story-telling meet."
    xml.language @channel_language || "en-us"

    xml.atom :link, href: rss_feed_url(format: :xml), rel: "self", type: "application/rss+xml", target: "_self"

    xml.lastBuildDate (@posts.first&.publish_date&.rfc822) || Time.now.rfc822

    @posts.each do |post|
      xml.item do
        xml.title post.title

        # --- Corrected Item Link ---
        if post.publish_date
          item_url = post_url(year: post.publish_date.year,
                              month: post.publish_date.strftime("%02m"),
                              slug: post.slug)
          xml.link item_url

          # --- Corrected GUID ---
          xml.guid item_url, isPermaLink: "true"

          xml.pubDate post.publish_date.rfc822
        else
          # xml.guid "Error: Missing publish date for post with slug #{post.slug}", isPermaLink: "false"
          Rails.logger.warn "Skipping post '#{post.title || post.slug}' in RSS feed due to missing publish_date."
          next
        end

        # --- Description (Correct) ---
        xml.description { xml.cdata! post.content_html }

        # --- Optional: Author ---
        # xml.author post.author_email_or_name if post.respond_to?(:author_email_or_name) && post.author_email_or_name

        # --- Optional: Categories (Tags) ---
        if post.tags.present?
          post.tags.split(",").map(&:strip).each do |tag|
            xml.category tag
          end
        end
      end # xml.item
    end # @posts.each
  end # xml.channel
end # xml.rss
