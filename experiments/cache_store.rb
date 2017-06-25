#!/usr/bin/env ruby

require "set"
require "benchmark"

def test_sorted(max_idx)
  puts "preparing..."
  arr_orig = (0..max_idx).to_a
  arr_1 = arr_orig.dup
  new_elm = arr_1.delete(arr_1.sample)
  arr_2 = arr_1.dup
  arr_3 = arr_1.dup
  set_1 = SortedSet.new(arr_1)
  hash_orig={}; arr_1.each{|i| hash_orig[i] = 'asd' }
  hash = hash_orig.dup
  hash.delete new_elm

  puts "testing insert..."

  Benchmark.bm do |x|
    x.report('index          ') { arr_1.insert(  arr_1.index { |x| x > new_elm }                           , new_elm) }
    x.report('each_with_index') { arr_2.insert(  [*arr_2.each_with_index].bsearch{|x, _| x > new_elm}.last , new_elm) }
    x.report('bsearch_index  ') { arr_3.insert(  arr_3.bsearch_index{|x, _| x > new_elm}                   , new_elm) }
    x.report('sortedset      ') { set_1 << new_elm }
    x.report('hash           ') { hash[new_elm] = 'asd' }
  end
  # puts arr_1.join(" ")
  puts (arr_orig == arr_1).to_s

  # puts arr_2.join(" ")
  puts (arr_orig == arr_2).to_s

  # puts arr_3.join(" ")
  puts (arr_orig == arr_3).to_s

  # puts set_1.to_a.join(" ")
  puts (arr_orig == set_1.to_a).to_s

  # puts set_1.to_a.join(" ")
  puts (hash_orig == hash).to_s

  puts "search..."

  Benchmark.bm do |x|
    x.report('index          ') { puts arr_1.index { |x| x > new_elm } }
    x.report('each_with_index') { puts [*arr_2.each_with_index].bsearch{|x, _| x > new_elm}.last }
    x.report('bsearch_index  ') { puts arr_3.bsearch_index{|x, _| x > new_elm} }
    x.report('sortedset      ') { puts set_1.find_index new_elm }
    x.report('hash           ') { puts hash[new_elm] }
  end

end

test_sorted eval(ARGV[0])

# WINNER 25/Jun/2017: HASH


