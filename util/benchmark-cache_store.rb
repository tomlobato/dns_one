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

# RUN 25/Jun/2017
# WINNER: HASH

# $ ./cache_store.rb 1e7
# preparing...
# testing insert...
#        user     system      total        real
# index            1.170000   0.070000   1.240000 (  1.347434)
# each_with_index  6.300000   0.680000   6.980000 (  9.786449)
# bsearch_index    0.050000   0.110000   0.160000 (  0.391675)
# sortedset        0.000000   0.000000   0.000000 (  0.000026)
# hash             0.000000   0.000000   0.000000 (  0.000012)
# true
# true
# true
# true
# false
# search...
#        user     system      total        real
# index          5255680
#   1.090000   0.020000   1.110000 (  2.041613)
# each_with_index5255680
#   5.920000   1.220000   7.140000 (  8.701748)
# bsearch_index  5255680
#   0.000000   0.000000   0.000000 (  0.000054)
# sortedset      5255679
#   1.110000   0.000000   1.110000 (  1.110011)
# hash           asd
#   0.000000   0.000000   0.000000 (  0.000027)


