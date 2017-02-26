# This "should" work on Jekyll 3.x, but we're using Jekyll 2.x
#Jekyll::Hooks.register :site, :pre_render do |site, payload|
#  # Sort pinned posts up!
#  # https://talk.jekyllrb.com/t/pinned-posts-like-wordpress/1595/4
#
#  pinned_posts = payload['site']['posts'].select { |p| p.data['pinned'] }
#  pinned_posts.sort_by!{ |p|
#    pinned = p.data['pinned']
#    if pinned == true
#      pinned = 1
#    elsif pinned == false
#      pinned = 0
#    end
#    [pinned, p.date]
#  }.reverse!
#  payload['site']['pinned'] = pinned_posts
#end

class PinnedPosts < Octopress::Hooks::Site
  def merge_payload(payload, site)
    # Sort pinned posts up!
    # https://talk.jekyllrb.com/t/pinned-posts-like-wordpress/1595/4

    pinned_posts = payload['site']['posts'].select { |p| p.data['pinned'] }
    pinned_posts.sort_by!{ |p|
      pinned = p.data['pinned']
      if pinned == true
        pinned = 1
      elsif pinned == false
        pinned = 0
      end
      [pinned, p.date]
    }.reverse!
    payload['site']['pinned'] = pinned_posts
    {}
  end
end
