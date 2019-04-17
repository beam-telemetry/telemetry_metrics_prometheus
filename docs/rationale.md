# Rationale

We love the `:telemetry` ecosystem and everything it has to offer for instrumentation
of our applications! We also love Prometheus, but wiring up handlers is time 
consuming and we couldn't find an existing Prometheus library that met our needs and
offered the `:telemetry` + `Telemetry.Metrics` integration that we wanted.

This project aims to fit a very specific need: reporting of `:telemetry` events in
Prometheus format via `Telemetery.Metrics` definitions. There is no aim to create
a full Prometheus client library. 

We think this package provides the best way to collect metrics in Elixir for Prometheus, 
but if your needs are different, other existing works may be a better fit. Check out the 
BEAM OpenCensus project, especially if you need a solution for Erlang.


## Why include a server?

  1. It requires no modifications to your existing web server (assuming your
  app even has one!). It's much simpler to run a separate server versus
  adding a route and wiring up your scrape.
  2. Security. You don't have to lock down a route. You can keep the port
  the reporter is running on from being exposed to the outside world
  very simply with your infra configuration.
  3. Do you even web server, bruh? Maybe you're using Nerves! Maybe you want 
  to instrument a background task. Whatever the case may be, we aim to make
  it easy to scrape via the included web server or push scrapes to a destination.
