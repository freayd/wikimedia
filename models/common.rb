class Article < ActiveRecord::Base
    validates :title, presence: true
end

class Disambiguation < Article
end

class Redirect < Article
    belongs_to :redirect, class_name: 'Article'
    validates :redirect, presence: true
end
