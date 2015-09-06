require 'bundler/setup'
require 'treat'
require 'scalpel'
require 'engtagger'
require 'set'
require 'pry'


WORD_CATEGORIES = ["determiner", "adverb", "noun", "unknown", "verb", "pronoun", "conjunction", "preposition", "adjective", :unknown, "symbol", "interjection"]
include Treat::Core::DSL

if ARGV.empty?
  puts "usage: [document_1] [document_2] ..."
  exit
end

document_paths = ARGV
documents = document_paths.map do |path|
  document = document(path)
  document.apply(:chunk, :segment, :tokenize, :category)

  document
end

Metric = Struct.new(:name, :values)

class DocumentTest
  attr_reader :documents

  def initialize(documents)
    @documents = documents
  end
end

class WordTypeDensityTest < DocumentTest
  def initialize(documents, word_types)
    super(documents)
    @word_types = Set.new(word_types)
  end

  def test
    densities = documents.map do |document|
      words = document.words
      total_words = words.size

      word_type_totals = count_words_by_type(words)
      calculate_densities(total_words, word_type_totals)
    end

    @word_types.map do |word_type|
      densities_for_type = densities.map { |densities_for_doc| densities_for_doc.fetch(word_type, 0) }
      Metric.new("#{word_type}_density", densities_for_type)
    end
  end

  private

  def calculate_densities(total_words, word_type_totals)
    word_type_totals.reduce({}) do |h, (type, word_type_total)|
      h[type] = Float(word_type_total) / Float(total_words)
      h
    end
  end

  def count_words_by_type(words)
    word_type_totals = Hash.new(0)
    words.each do |word|
      category = word.category
      next unless @word_types.include?(category)

      word_type_totals[category] += 1
    end

    word_type_totals
  end
end

density_test = WordTypeDensityTest.new(documents, WORD_CATEGORIES)
metrics = density_test.test
metrics.each do |metric|
  puts "test: #{metric.name} values: #{metric.values}"
end
