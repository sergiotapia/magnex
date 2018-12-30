# Magnex

This library helps you search for torrents from multiple popular websites and APIs
on the web.

## Dependencies

This library uses Erlang's built in httpc http/1.1 client to perform all web requests.

A JSON parser, which you will configure in your app and tell Magnex about.

A HTML parser, Floki.

## Setup

### Add the library

Add the library to your `mix.exs` file.

TODO

### Tell Magnex about your JSON parser.

Because Magnex has no dependencies, you need to install your own JSON parser. Chances are you
already have one set up in your mix.exs file. (I recommend [Jason](https://github.com/michalmuskala/jason))

In your config.exs tell Magnex about your json parser. Here's an example using Jason:

```elixir
config :magnex, json_library: Jason
```

### Set your environment variable MAGNEX_APP_NAME.

We ask for this environment variable to allow Magnex to tell websites and APIs who
is requesting the data. This value will be your app name.

Here's an example using a .env file.

```
export MAGNEX_APP_NAME=mycoolapp
```

Then just `source .env` in your terminal to load the environment variable.

You're good to go!

## Examples

View our docs to see all supported features, but mostly you'll interact with these
two functions.

- `latest/0`

- `search/1`

Here's an example for rarbg.

```elixir
iex> Magnex.Crawlers.Rarbg.latest
iex> {:ok, [%Torrent{}...]}

iex> Magnex.Crawlers.Rarbg.search("big buck bunny")
iex> {:ok, [%Torrent{}...]}
```

## Supported Websites/APIs

Here's a list of supported sites and APIs. If one isn't working, open up an issue
for us.

- rarbg
- leetx
