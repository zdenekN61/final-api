# final-api

The API for final-CI. It is responsible for enqueing, monitoring and
shutdown of tests.

It features advanced query language to filter test results.

It is connected to other supporting services, such as:
* [node_starter](https://github.com/AVGTechnologies/node_starter)
* [travis-test-results](https://github.com/final-ci/travis-test-results)
* [travis-logs](https://github.com/AVGTechnologies/travis-logs)

## Development

* checkout the repository
* checkout related projects:
 * [travis-test-results](https://github.com/final-ci/travis-test-results)
 * [travis-logs](https://github.com/AVGTechnologies/travis-logs)
* in project travis-test-results
 * adjust the config examples in `config/` and remove the `.example` suffix
 * create an empty database using `psql`
 * execute `bundle && rake db:migrate`, you need Ruby 2.1.5 to do this
   currently
* in project travis-logs
 * adjust the config examples in `config/` and remove the `.example` suffix
 * create an empty database using `psql`
 * execute `bundle && rake db:migrate`, you need Ruby 2.1.5 to do this
   currently
* run `bundle install`
* run `rspec` to verify unit tests are passing

## Contributing

Due to the dependency on proprietary TSD Validator, contributing to this
project is not recommended at the moment.

## License

The service is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
