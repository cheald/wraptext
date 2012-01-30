module Wraptext
  class Parser
    BLOCK_TAGS = %w"table thead tfoot caption col colgroup tbody tr td th div dl dd dt
    ul ol li pre select option form map area blockquote address math style input hr
    fieldset legend section article aside hgroup header footer nav p
    figure figcaption details menu summary h1 h2 h3 h4 h5 h6 script"
    BLOCK_TAGS_LOOKUP = Hash[*BLOCK_TAGS.map {|e| [e, 1]}.flatten]

    NO_WRAP_TAG = %w"table thead tfoot caption col colgroup tbody tr td th dl dd dt
    ul ol li pre select option form map area math style input hr
    fieldset legend section article aside hgroup header footer nav
    figure figcaption details menu summary h1 h2 h3 h4 h5 h6 script"
    NO_WRAP_TAG_LOOKUP = Hash[*NO_WRAP_TAG.map {|e| [e, 1]}.flatten]

    STRAIGHT_COPY_TAGS = %w"script pre textarea"
    STRAIGHT_COPY_TAGS_LOOKUP = Hash[*STRAIGHT_COPY_TAGS.map {|e| [e, 1]}.flatten]
    MULTIPLE_NEWLINES_REGEX = /(\r\n|\n){2,}/

    def self.parse(text)
      new(text).to_html
    end

    def initialize(text_or_nokogiri_doc)
      @doc = if text_or_nokogiri_doc.is_a? Nokogiri::XML::Document
        text_or_nokogiri_doc
      elsif text_or_nokogiri_doc.is_a? String
        Nokogiri::HTML text_or_nokogiri_doc
      else
        raise "#initialize requires a string or Nokogiri document"
      end
      @root = Nokogiri::HTML "<body></body>"
      reparent_nodes @root.xpath("/html/body").first, @doc.xpath("/html/body").first
      strip_empty_paragraphs!
    end

    def to_html      
      @html ||= @root.xpath("/html/body").inner_html
    end

    def to_doc
      @doc_out ||= @root.xpath("/html/body").first
    end

    private

    def strip_empty_paragraphs! 
      @root.xpath("//p").each do |n|
        if n.inner_html.strip == ''
          n.remove
        elsif n.content.strip == ''
          n.parent.add_child n.children
          n.remove
        end
      end
    end    

    # This traverses the entire document, and where it finds double newlines in text,
    # it replaces them with <p> tags. This is a document-oriented approach to this
    # problem, rather than a regex-oriented one like Wordpress takes in PHP.
    # simple_format is not appropriate here, as it does not consider block-level
    # html element context when performing substitutions.
    def reparent_nodes(top, parent)
      for i in (0..parent.children.length - 1) do
        node = parent.children[i]
        # Block-level tags like <div> and <blockquote> should be traversed into.
        if BLOCK_TAGS_LOOKUP.has_key? node.name
          # If we hit a block-level tag, we need to unwind any <p> tags we've inserted; block level elements are
          # siblings to <p> tags, not children.
          top = top.parent while top.name == "p"

          # Some tags we don't want to traverse into, like <pre> and <script>. Just copy them into the doc.
          if STRAIGHT_COPY_TAGS_LOOKUP.has_key? node.name
            top.add_child node.clone
          else
            # If this is a block-level element, we'll create a new empty version of it, stick it into the doc,
            # then recurse over the original node's children to populate it.
            copy = @root.create_element node.name, node.attributes
            top.add_child copy
            reparent_nodes copy, node
          end

        # If this is a text node, we need to make sure it gets wrapped in a P, unless it's in an element that
        # effectively replaces <p>, like <h1>.
        # Text is split on double newlines, and each element is given its own <p> tag. If the text already exists
        # in a <p> tag, the existing tag is re-used for the first chunk.
        elsif node.text?
          node.content.split(MULTIPLE_NEWLINES_REGEX).each_with_index do |text, index|
            if (index == 0 and top.name == "p") or NO_WRAP_TAG_LOOKUP.has_key?(top.name)
              top.add_child @root.create_text_node(text)
            elsif top.name == "p"
              p = @root.create_element "p", text
              top.after p
              top = p
            else
              p = @root.create_element "p", text
              top.add_child p
              top = p
            end
          end
          
        # If this isn't a block or text node, we need to copy it into the new document. If it's a <p> node, then
        # we just copy it in directly. Else, wrap it in a <p> tag and copy it in.
        # This allows things like "<em>Foo</em> Bar Baz" to be wrapped in a single tag, as the <em> tag will be
        # wrapped in a <p> tag, then the text node will reuse the existing <p> tag when it is parsed.
        else
          if top.name == "p"
            top.add_child node.clone
          else
            p = @root.create_element "p", text
            top.add_child p
            top = p
          end
        end
      end
    end
  end
end