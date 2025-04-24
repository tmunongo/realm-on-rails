require "test_helper"
require "fileutils"

class PostLoaderServiceTest < ActiveSupport::TestCase
  def test_file_path
    Rails.root.join("content", "posts", "2023", "01", "test-post.md")
  end

  # Use setup and teardown to manage the test file
  setup do
    FileUtils.mkdir_p(File.dirname(test_file_path))
    File.write(test_file_path, <<~MARKDOWN)
      ---
      title: Test Post
      description: A test post
      minutes_read: 1
      publish_date: 2023-01-01
      ---

      # This is the test content

      Some more content.
    MARKDOWN
  end

  teardown do
    # Clean up the dummy file and directory
    FileUtils.rm_f(test_file_path)
    # You might want to remove the directories if they were created by setup,
    # but be careful not to delete actual content directories.
    # A safer approach is often just deleting the file.
  end


  test "load_all returns an array of post objects" do
    # This test might need adjustments if load_all depends on files existing
    # in the file system. Consider creating multiple dummy files here if needed.
    posts = PostLoaderService.load_all
    assert_instance_of Array, posts
    assert posts.all? { |post| post.is_a?(Post) }, "All elements should be Post instances"
  end

  test "load_from_file returns a Post object" do
    # Use the test_file_path defined in the method
    post = PostLoaderService.load_from_file(test_file_path)

    assert_instance_of Post, post # This line is failing
    assert_equal "Test Post", post.title
    assert_equal "A test post", post.description
    assert_equal 1, post.minutes_read
    assert_equal Date.new(2023, 1, 1), post.publish_date
    # Note: Slug is likely derived from the filename, without the extension
    assert_equal "test-post", post.slug
    assert_equal test_file_path.to_s, post.file_path
    assert_kind_of String, post.content_md
    assert_kind_of String, post.content_html
  end
end
