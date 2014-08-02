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

    it 'should return a string from #to_text' do
      @doc.to_text.should be_a(String)
    end
  end

  context "given a set of plain text" do
    let(:text) {<<-EOF
      This is some text.

      This is some more text.
      EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it "should convert plain text to p-wrapped text" do
        expects = <<-EOF
<p>This is some text.</p>
<p>This is some more text.</p>
EOF
        doc.to_html.should == expects.strip
      end
    end

    describe '#to-text'  do
      it 'should do nothing to p-wrapped text' do
        doc.to_text.should == text.strip
      end
    end
  end

  context "given plain text with a block element in the middle" do
    let(:text) {<<-EOF
This is some text
<div>This is a block level element</div>
This is some text after the block element
EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it "should respect block-level elements" do
        expects = <<-EOF
<p>This is some text</p>
<div><p>This is a block level element</p></div>
<p>This is some text after the block element</p>
EOF
        doc.to_html.should == expects.strip
      end
    end

    describe '#to_text'  do
      it 'should seperate block-level elements with newlines' do
        expects = <<-EOF
This is some text
This is a block level element
This is some text after the block element
EOF
        doc.to_text.should == expects.strip
      end
    end
  end


  context "given plain text with some p-peer tags" do
    let(:text) {<<-EOF
This is some text
<h1>This is a p-peer element</h1>
This is some text after the block element
EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it "should not inject p tags directly inside p-peer tags" do
        expects = <<-EOF
<p>This is some text</p>
<h1>This is a p-peer element</h1>
<p>This is some text after the block element</p>
EOF
        doc.to_html.should == expects.strip
      end
    end

    describe '#to_text' do
      it 'should seperate block-level elements with newlines' do
        expects = <<-EOF
This is some text
This is a p-peer element
This is some text after the block element
EOF
        doc.to_text.should == expects.strip
      end
    end
  end

  context "given a <script> tag" do
    let(:text) {<<-EOF
This is some precursor text

And another line
<script>
  var elem = 'this is some javascript';

  elem = elem.toUpperCase();
</script>
EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it "should not perform any transformation inside the tag" do
        expects = <<-EOF
<p>This is some precursor text</p>
<p>And another line</p>
<script>
  var elem = 'this is some javascript';

  elem = elem.toUpperCase();
</script>
EOF
        doc.to_html.should == expects.strip
      end
    end
  end

  # todo
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

  context "given a p with em inside it" do
    let(:text) {<<-EOF
<p>
  This is some <em>emphasized</em> text

  And here is <i>another</i> line
</p>
EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it 'preserves non block-level tags' do
        expects = <<-EOF
<p>This is some <em>emphasized</em> text</p>
<p>And here is <i>another</i> line</p>
EOF
        doc.to_html.should == expects.strip
      end
    end

    describe '#to_text' do
      it 'removes block-level and non block-level tags' do
        expects = <<-EOF
  This is some emphasized text

  And here is another line
EOF
        doc.to_text.should == expects.strip
      end
    end
  end

  context "given an empty document" do
    it 'should not raise an error' do
      expect { Wraptext::Parser.new("") }.to_not raise_error
    end
  end

  context "given an article with two concurrent non-block tags" do
    let(:text) {<<-EOF
      A "Get the Facts" button sends you to a <em>Washington Post</em> <a href="http://www.washingtonpost.com/wp-srv/special/politics/campaign-finance/" target="_blank">article</a> about campaign finance.
    EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it "should preserve spacing between non-block tags" do
        doc.to_html.should match("</em> <a")
      end
    end

    describe '#to_text' do
      it "should preserve spacing between non-block tags" do
        doc.to_text.should match("Post article")
      end
    end
  end

  context "given an article with leading script tags" do
    let(:text) {<<-EOF
<script type='text/javascript' src='http://WTXF.images.worldnow.com/interface/js/WNVideo.js?rnd=543235;hostDomain=www.myfoxphilly.com;playerWidth=645;playerHeight=362;isShowIcon=true;clipId=8157027;flvUri=;partnerclipid=;adTag=Morning%2520Show;advertisingZone=;enableAds=true;landingPage=;islandingPageoverride=false;playerType=STANDARD_EMBEDDEDscript;controlsType=overlay'></script><a href="http://www.myfoxphilly.com" title="Philadelphia News, Weather and Sports from WTXF FOX 29">Philadelphia News, Weather and Sports from WTXF FOX 29</a>

Viewers of <em>Good Day Philadelphia</em> got a surprise Wednesday morning when Mark Wahlberg stopped by to do the weather and traffic.

Wahlberg, who is promoting his upcoming movie <em>Broken City</em>, delivered the impromptu report on Fox affiliate WTXF. Looking ahead to the seven-day forecast, Wahlberg, joined by <em>Broken City</em> Director Allen Hughes, pronounced Wednesday's 54 degrees "perfect golf weather." Wahlberg then slipped into a Philly accent for the traffic report: "Look at this congestion here. We're expecting 40- to 45-minute delays if you're coming east bound on the 676 here. You're going to have some serious problems. Why don't you stop and get yourself a hoagie?"

Wahlberg goofs amiably but he's a long way from topping Sacha Baron Cohen's local news cameo in <em>Borat</em> below.


<iframe width="640" height="360" src="http://www.youtube.com/embed/KlXd9cooOhE" frameborder="0" allowfullscreen></iframe>
EOF
    }

    let(:doc) { Wraptext::Parser.new(text) }

    describe '#to_html' do
      it 'should not strip leading script tags' do
        doc.to_html.should match("<script")
      end
    end

    describe '#to_text' do
      it 'should strip leading script tags' do
        doc.to_text.should_not match("<script")
      end
    end
  end
end
