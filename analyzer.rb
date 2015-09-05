require 'bundler/setup'
require 'treat'
require 'scalpel'
require 'engtagger'
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
  document.apply(:chunk, :segment, :tokenize)

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
  def initialize(documents, word_type)
    super(documents)
    @word_type = word_type
  end

  def test
    metric_values = documents.map do |document|
      words = document.words
      words_of_type = words.select { |word| word.category == @word_type }

      total_words = words.size
      total_words_of_type = words_of_type.size

      Float(total_words_of_type) / Float(total_words)
    end

    Metric.new("#{@word_type}_density", metric_values)
  end
end

WORD_CATEGORIES.each do |category|
  density_test = WordTypeDensityTest.new(documents, category)
  metric = density_test.test
  puts "test name: #{metric.name} values: #{metric.values}"
end
