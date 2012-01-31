require 'spec_helper'

describe Wraptext::Parser do
  it "should accept a String document" do
    Wraptext::Parser.new("This is a string document").should be_a(Wraptext::Parser)
  end

  it "should accept a Nokogiri document" do
    doc = Nokogiri::HTML "<body>foo</body>"
    Wraptext::Parser.new(doc).should be_a(Wraptext::Parser)
  end

  context "given a document" do
    before :each do
      doc = <<-EOF
      This is some text.

      This is some more text.
      EOF
      @doc = Wraptext::Parser.new(doc)
    end

    it "should return a string from #to_html" do
      @doc.to_html.should be_a(String)
    end

    it "should return a Nokogiri::XML::Element from #to_doc" do
      @doc.to_doc.should be_a(Nokogiri::XML::Element)
    end    
  end

  context "given a set of plain text" do
    before :each do
      doc = <<-EOF
      This is some text.

      This is some more text.
      EOF
      @doc = Wraptext::Parser.new(doc)
    end

    it "should convert plain text to p-wrapped text" do
      expects = <<-EOF
<p>This is some text.</p>
<p>      This is some more text.
</p>
EOF
      @doc.to_html.should == expects.strip
    end
  end

  context "given plain text with a block element in the middle" do
    it "should respect block-level elements" do
      doc = <<-EOF
This is some text
<div>This is a block level element</div>
This is some text after the block element
EOF
      expects = <<-EOF
<p>This is some text
</p>
<div><p>This is a block level element</p></div>
<p>
This is some text after the block element
</p>
EOF
      Wraptext::Parser.new(doc).to_html.should == expects.strip
    end
  end

  
  context "given plain text with some p-peer tags" do
    it "should not inject p tags directly inside p-peer tags" do
      doc = <<-EOF
This is some text
<h1>This is a p-peer element</h1>
This is some text after the block element
EOF
      expects = <<-EOF
<p>This is some text
</p>
<h1>This is a p-peer element</h1>
<p>
This is some text after the block element
</p>
EOF
      Wraptext::Parser.new(doc).to_html.should == expects.strip
    end
  end  

  context "given a <script> tag" do
    it "should not perform any transformation inside the tag" do
      doc = <<-EOF
This is some precursor text

And another line
<script>
  var elem = 'this is some javascript';

  elem = elem.toUpperCase();
</script>
EOF
      expects = <<-EOF
<p>This is some precursor text</p>
<p>And another line
</p>
<script>
  var elem = 'this is some javascript';

  elem = elem.toUpperCase();
</script>
EOF
      Wraptext::Parser.new(doc).to_html.should == expects.strip      
    end
  end
 
  context "given Wordpress datasets" do
    before :all do
      @in = File.expand_path(File.join(__FILE__, "..", "..", "data", "in"))
      @out = File.expand_path(File.join(__FILE__, "..", "..", "data", "out"))
    end

    def clean_data(data)
      data.gsub(/[\r\n\s]+/, " ").
      gsub(/>/, ">\n").
      gsub(" />", ">").
      split(/\n/).
      map(&:strip).      
      join("\n").strip
    end 

    def test_datafile(file)
      data_in = File.read(file)
      control = File.read(File.join(@out, File.basename(file)))
      out = Wraptext::Parser.new(data_in).to_html
      clean_data(out).should == clean_data(control)
    end

    Dir.glob( File.expand_path(File.join(__FILE__, "..", "..", "data", "in", "*")) ).each do |file|
      it "should generate equivalent HTML for #{File.basename(file)}" do
        test_datafile file
      end
    end
  end

  context "Given a p with em inside it" do
    doc = <<-EOF
<p>
  This is some <em>emphasized</em> text

  And here is <i>another</i> line
</p>
EOF

    expects = <<-EOF
<p>
  This is some <em>emphasized</em> text</p>
<p>  And here is <i>another</i> line
</p>
EOF
    Wraptext::Parser.new(doc).to_html.should == expects.strip      
  end  
end
