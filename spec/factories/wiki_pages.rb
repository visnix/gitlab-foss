# frozen_string_literal: true

require 'ostruct'

FactoryBot.define do
  factory :wiki_page do
    transient do
      title { generate(:wiki_page_title) }
      content { 'Content for wiki page' }
      format { 'markdown' }
      project { create(:project) }
      attrs do
        {
          title: title,
          content: content,
          format: format
        }
      end
    end

    page { OpenStruct.new(url_path: 'some-name') }
    wiki { build(:project_wiki, project: project) }

    initialize_with { new(wiki, page) }

    before(:create) do |page, evaluator|
      page.attributes = evaluator.attrs
    end

    to_create do |page|
      page.create
    end
  end

  factory :wiki_page_meta, class: 'WikiPage::Meta' do
    title { generate(:wiki_page_title) }
    project { create(:project) }

    trait :for_wiki_page do
      transient do
        wiki_page { create(:wiki_page, project: project) }
      end

      initialize_with { wiki_page.meta }
    end
  end

  factory :wiki_page_slug, class: 'WikiPage::Slug' do
    wiki_page_meta { create(:wiki_page_meta) }
    slug { generate(:sluggified_title) }
    canonical { false }

    trait :canonical do
      canonical { true }
    end
  end

  sequence(:wiki_page_title) { |n| "Page #{n}" }
  sequence(:sluggified_title) { |n| "slug-#{n}" }
end
