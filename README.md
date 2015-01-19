# CrossDoc Ruby Library

CrossDoc is a platform-independent document interchange format.

This is the Ruby server library and JavaScript client library for CrossDoc.
It is the defacto standard implementation of CrossDoc PDF rendering.

## Installation

Add this line to your application's Gemfile:

    gem 'crossdoc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install crossdoc

## Usage


### Documents in HTML

Each CrossDoc document begins its life as an HTML view rendered in a browser.
This HTML structure uses a few conventions to tell CrossDoc how to serialize it.

A basic document is structured like this:

```html
<div class="crossdoc" id="document">
    <div class="page us-letter decorated margin-75" id="page1">
        <!-- Page Content -->
    </div>
    <div class="page us-letter decorated margin-75" id="page2">
        <!-- Page Content -->
    </div>
</div>
```

There is one containing div with class *crossdoc*.
Each page is it's own div with class *page*, and optional classes for formatting:

* Page size: *us-letter* (default) or *us-legal*
* Page margin: *margin-50*, *margin-75*, or *margin-100* for 1/2", 3/4", or 1" margins, respectively





## Contributing

1. Fork it ( http://github.com/<my-github-username>/crossdoc-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
