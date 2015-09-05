require 'bundler/setup'
require 'treat'
require 'scalpel'
require 'engtagger'

include Treat::Core::DSL

if ARGV.size != 2
  puts "usage: [document_1] [document_2]"
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

class NounDensityTest < DocumentTest
  def test
    metric_values = documents.map do |document|
      words = document.words
      nouns = words.select { |word| word.category == "noun" }

      total_words = words.size
      total_nouns = nouns.size

      total_nouns / total_words
    end

    Metric.new('noun_density', metric_values)
  end
end

puts NounDensityTest.new(documents).test
