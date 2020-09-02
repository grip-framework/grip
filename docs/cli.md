# CLI

A class which handles all of the CLI commands
that are provided to the compiled binary file of a `Grip` application.

It is responsible for loading the SSL/TLS certificate file and configuring
the application to accept the encrypted data.

It is responsible for updating the `HOST` and the `PORT` of the configuration
as well as prompting the help by using an `OptionParser` class.

## Code example

```ruby
cli = Grip::CLI.new(ARGV)
```