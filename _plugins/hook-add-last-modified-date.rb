# Get the current post last modified time
# @example {{ post.last_modified_date }}
#
Jekyll::Hooks.register :posts, :pre_render do |post|
  post.data['last_modified_date'] = File.mtime( post.path )
end
