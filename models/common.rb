require_relative '../lib/core_ext'

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

    def book(title: self.title, subtitle: nil,
             cover_image: nil, cover_color: nil, cover_text_color: nil,
             paper_size: 'a4', show_table_of_contents: 'auto', columns: 2,
             description: nil, sort_as: nil)
        parameters = {
            # Cover
            'title'       => title,
            'subtitle'    => subtitle,
            'cover-image' => cover_image,
            'cover-color' => cover_color,
            'text-color'  => cover_text_color,
            # Book Creator
            'setting-papersize' => paper_size,
            'setting-toc'       => show_table_of_contents,
            'setting-columns'   => columns,
            # Maintenance
            'description' => description,
            'sort_as'     => sort_as
        }

        <<-EOS.strip_heredoc(from_first_line: true).gsub(/^#{$/}$/, '')
            {{saved_book
             | #{ parameters.collect { |k, v| "#{k} = #{v}" if v }.compact.join("#{$/} | ") }
            }}

            == #{title} ==
            #{ "=== #{subtitle} ===" if subtitle }

            #{book_contents}

            [[Category:Books|#{title}]]"
        EOS
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
