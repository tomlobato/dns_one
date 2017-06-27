# DnsOne

[![Gem Version](https://badge.fury.io/rb/dns_one.svg)](https://badge.fury.io/rb/dns_one)
[![Code Climate](https://codeclimate.com/github/tomlobato/dns_one.svg)](https://codeclimate.com/github/tomlobato/dns_one)
![](http://ruby-gem-downloads-badge.herokuapp.com/dns_one?type=total&label=gem%20downloads)
 
By [Bettercall.io](https://bettercall.io/).

Instead having a complex data schema to assign record sets to DNS zones, dns_one assigns one or a few record sets to many zones.

Configure your record sets in YML files and fetch your domains from a database or YML backend.

## Installation

    # gem install dns_one

## Usage

    # dns_one install

Configure ```/etc/dns_one/conf.yml```. Then:

    # dns_one start

Also:

    # dns_one status
    # dns_one stop
    # dns_one uninstall

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Compatibility

IPV6 error in Ruby 2.3.0:  

variables address, a1 and a2 should`nt be frozen in 2.3.0/lib/ruby/2.3.0/resolv.rb

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomlobato/dns_one.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

