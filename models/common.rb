class Article < ActiveRecord::Base
    validates :title, presence: true

    def inspect
        title.inspect
    end

    def follow_redirect
        self
    end

    def internal_links
        return [] unless text

        links = []
        text.scan(/\[\[\s*([a-zA-Z _\-#]+)(?:\s*\|\s*([a-zA-Z _\-#\|]*\s*))?\]\]([a-zA-Z]*)/) do |link|
            title = link[0]
            label = (link[1] || '') + link[2]
            if label.empty?
                label = title
            elsif !label.match(/^\s+$/)
                label.rstrip!
            end
            links << { title: title, label: label }
        end

        # TODO Scan for the {{seealso}} template (preferably in the same regexp so the order is respected

        links
    end

    def book(paper_size: 'a4', table_of_contents: 'auto', columns: 2)
        puts <<-EOS.strip_heredoc
            {{saved_book
             | setting-papersize = #{paper_size}
             | setting-toc = #{table_of_contents}
             | setting-columns = #{columns}
            }}

            == #{title} ==
        EOS
        puts book_contents
    end

    def book_contents
        book_entry
    end

    def book_entry
        ":[[#{title}]]"
    end
end

class Disambiguation < Article
end

class Redirect < Article
    belongs_to :redirect, class_name: 'Article'
    validates :redirect, presence: true

    def follow_redirect
        redirect
    end

    def book
        redirect.book
    end

    def book_contents
        redirect.book_contents
    end

    def book_entry
        redirect.book_entry
    end
end
