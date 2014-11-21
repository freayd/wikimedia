class CreateArticles < ActiveRecord::Migration
    def change
        create_table :articles do |t|
            t.string     :title
            t.string     :type
            t.text       :text
            t.references :redirect
            t.string     :status # Wikivoyage specific
            t.references :parent # Wikivoyage specific
        end

        add_index :articles, :title, unique: true
    end
end
