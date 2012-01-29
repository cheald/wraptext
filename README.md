# Wraptext
## What is it?

Wraptext is a small library designed to accept "blog-style" newline-delimited text with markup, and to return a formatted document with bare text wrapped in `<p>` tags, splitting text nodes with double newlines in them into multiple paragraphs.

## How to use it

Add it to your gemfile:

    gem 'wraptext'

Then parse your text with it:

    Wraptext::Parser.new(your_html_fragment).to_html

This'll return your text fragment with bare text wrapped in paragraph tags, and text nodes that include double newlines split into distinct paragraphs. The primary intent was to enable parsing of Wordpress-generated post content into valid HTML documents, but because the parser is designed to work on generic HTML documents, may be used beyond Wordpress content.

`Wraptext::Parser` accepts a Nokogiri document, as well, if you already have an existing document you are working with. Wraptext will *not* modify the original document object you pass in; it will create its own internal Nokogiri document to build the new document tree from. You may access this new document with `#to_doc`, if desired.


## Why not simple_format?

simple_format is not HTML-aware, and may potentially mangle HTML in ways that you don't want. For example, it would mangle `<script>` and `<pre>` sections in text, breaking them.

## Why not regexes, like Wordpress does it?

Mostly because parsing HTML with regexes is almost never the right solution. Using Nokogiri ensures a properly-formed document.