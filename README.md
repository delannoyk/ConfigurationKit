ConfigurationKit
================

[![Build Status](https://travis-ci.org/delannoyk/ConfigurationKit.svg)](https://travis-ci.org/delannoyk/ConfigurationKit)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Cocoapods Compatible](https://img.shields.io/cocoapods/v/ConfigurationKit.svg)
![Platform iOS](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
[![Contact](https://img.shields.io/badge/contact-%40kdelannoy-blue.svg)](https://twitter.com/kdelannoy)
[![codecov.io](https://codecov.io/github/delannoyk/ConfigurationKit/coverage.svg?branch=master)](https://codecov.io/github/delannoyk/ConfigurationKit?branch=master)

Have you ever been in a situation where you submitted a build on the App Store with
wrong API Keys, environment URLs and such? Well, ConfigurationKit is here to help.

# Introduction
A `Configuration` is basically a `Dictionary` that is supposed to contain
everything related to configuring your app (it can be anything: API keys, URLs, ...).
This `Configuration` refreshes itself and alerts you of any change by
downloading a new version of your file upon events that you can configure:

* App startup,
* App enters foreground,
* At defined time intervals,
* A custom `EventProducer`.

A refresh cycle can be done thanks to 3 protocols:

* An `URLBuilder` servers the purpose of building a valid `NSURLRequest`
when it's needed. Using this allows you to configure everything you can use to
call your server (HTTP Headers, Cookies, Signed URL, ...).
* A `Parser` transforms raw `NSData` into a usable `Dictionary`.
* And an `Encryptor` because security matters for these kinds of data. It lets
you decrypt data coming from your server in order to be parsed right after.

Of course, you will probably want to have an initial configuration (hardcoded or
bundled in your application resources) and use it, but you will also want to
use the last configuration available. That is why `Cacher` has been introduced
to the framework: in order to cache the latest version of the configuration.
Again, because security matters, another `Encryptor` can be used to encrypt data
before calling any method of the `Cacher`.

# Usage

TODO

# Installation

TODO

# Default implementation
ConfigurationKit provides default implementation for most of the protocols
implementation needed by a `Configuration`.

## Cacher
### FileCacher
A `FileCacher` is a `Cacher` implementation that saves data in multiple files.

You can create a `FileCacher` by initializing it with the path to a directory
where to save files in and by giving it options used to save files.

The only option right now is `.IncludeInBackup` and allows you to define that
new configuration should be included in application backup (iTunes and iCloud).

## URLBuilder
### SimpleURLBuilder
A `SimpleURLBuilder` is an `URLBuilder` implementation that uses a static URL in
order to create the `NSURLRequest`.

## Parser
### PListParser
A `PListParser` is an implementation of `Parser` that reads a configuration from
plist data.

### FlatJSONParser
A `FlatJSONParser` is an implementation of `Parser` that reads a configuration
from a JSON file that can be represented as a `[String: String]`. For example:
```json
{
    "key1": "value1",
    "key2": "value2",
    "key3": "value3"
}
```

## EventProducer
### ApplicationEventProducer

TODO

### StopWatchEventProducer

TODO

### TimedEventProducer

TODO
