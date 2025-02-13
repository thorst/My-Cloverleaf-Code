if 0 {
    This method will replace html encoded values to thier
    correct hex counterparts.  You need to pass in a formatter
    because I wouldnt know what the reciving system would like.
    
    http://www.ascii.cl/htmlcodes.htm
    
    # Format in rtf wrapper
    echo [_hexReplaceHtml {hex {return "\{\\E\\rtf1 \\X$hex\\ \}"}} "&#162;"]
    
    # Similar but just \X**\ wrapper
    echo [_hexReplaceHtml {hex {return "\\X$hex\\"}} "&#162;"]
    
    # Example of returning raw hex
    echo [_hexReplaceHtml {hex {return [_hexFrString $hex]}} "&#162;"]
    
    The first argument is using tcl's apply (anonymous functions) so with 
    {i {incr i}} we can see that i is the expected parameter and incr i is the body
    this would be the same as writing the following proc, or some variation
    proc myIncr {i} {return [incr i];}
    
    If you needed to see the map you could do the following, assuming your in a proc
    which if you are in the engine you are.
    upvar #0 "[info level 0]_hexReplaceHtmlMap" map 
    echo $map
    
    If you arent in a proc or arent in the engine you could do this.
    upvar #0 "_hexReplaceHtmlMap" map 
    echo $map
}
proc _hexReplaceHtml {lambda {string "none"}} {

    if {$string =="none"} {
        upvar segList segList
    } else {
        set segList $string
    }
    
    # The first and last info level are the current proc, so if 0 and 1 are equal
    # you are calling this from outside of a proc. Meaning outside the engine.
    # In this case we just use the generic _hexReplaceHtmlMap variable which
    # could leave room for errors if two scripts are using the same interpreter
    # that use this proc but with different lambda
    if {[info level 1]==[info level 0]} {
        set globalVar "_hexReplaceHtmlMap"
    } else {
        set globalVar "[info level 1]_hexReplaceHtmlMap"
    }
    upvar #0 $globalVar _hexReplaceHtmlMap
    
    
    # Build the dict from a csv file, each record may have the number code as well as common name such as \xA0 (hex), &#160; (number), &nbsp; (name)
    if {![info exists _hexReplaceHtmlMap]} {
    set codeList {HEX,Code,String
A0,&#160;,&nbsp;
A1,&#161;,&iexcl;
A2,&#162;,&cent;
A3,&#163;,&pound;
A4,&#164;,&curren;
A5,&#165;,&yen;
A6,&#166;,&brvbar;
A7,&#167;,&sect;
A8,&#168;,&uml;
A9,&#169;,&copy;
AA,&#170;,&ordf;
AB,&#171;,&laquo;
AC,&#172;,&not;
AD,&#173;,&shy;
AE,&#174;,&reg;
AF,&#175;,&macr;
B0,&#176;,&deg;
B1,&#177;,&plusmn;
B2,&#178;,&sup2;
B3,&#179;,&sup3;
B4,&#180;,&acute;
B5,&#181;,&micro;
B6,&#182;,&para;
B7,&#183;,&middot;
B8,&#184;,&cedil;
B9,&#185;,&sup1;
BA,&#186;,&ordm;
BB,&#187;,&raquo;
BC,&#188;,&frac14;
BD,&#189;,&frac12;
BE,&#190;,&frac34;
BF,&#191;,&iquest;
D7,&#215;,&times;
F7,&#247;,&divide;
7B,&#123;,
7C,&#124;,
7D,&#125;,
7E,&#126;,
60,&#96;,
5B,&#91;,
5C,&#92;,
5D,&#93;,
5E,&#94;,
5F,&#95;,
40,&#64;,
30,&#48;,
31,&#49;,
32,&#50;,
33,&#51;,
34,&#52;,
35,&#53;,
36,&#54;,
37,&#55;,
38,&#56;,
39,&#57;,
3A,&#58;,
3B,&#59;,
3C,&#60;,&lt;
3D,&#61;,
3E,&#62;,&gt;
3F,&#63;,
20,&#32;,
21,&#33;,
22,&#34;,&quot;
23,&#35;,
24,&#36;,
25,&#37;,
26,&#38;,&amp;
27,&#39;,
28,&#40;,
29,&#41;,
2A,&#42;,
2B,&#43;,
2C,&#44;,
2D,&#45;,
2E,&#46;,
2F,&#47;,}
    
        set isFirst 1
        set _hexReplaceHtmlMap ""
        foreach line $codeList {
            if {$isFirst} {set isFirst 0; continue;}
            
            set fields [split $line ","]
            if {[lindex $fields 1]!=""} {dict set _hexReplaceHtmlMap [lindex $fields 1] [apply $lambda [lindex $fields 0]];}
            if {[lindex $fields 2]!=""} {dict set _hexReplaceHtmlMap [lindex $fields 2] [apply $lambda [lindex $fields 0]];}
        }
    }
    
    # Replace all occurences in message
    set segList [string map -nocase $_hexReplaceHtmlMap $segList]
}