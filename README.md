# TimberText
TimberText is a tree-based markup language that is designed for sectioned documents


## Design Goals

There are a ton of existing markup languages, so someone is surely wondering what TimberText has to offer that they do not. TimberText is:
* __For authors, not ASCII editors__  
  ASCII markup like Markdown is designed to be user legible and easily presentable in raw textual form. TT is designed to be parsed into naturally structured documents such as HTML or LaTeX. This allows authors to focus on the order and position of content, while being freed from complicated grammars.
* __Structured as Trees__  
  Trees make it much more logical when discerning where a section starts and finishes. They also allow easy expansion from an outline into a full document. TimberText takes advantage of this structure to allow for fast recursive parsing, as well as predictable conversion to other document formats. There aren't really any "gotchas" in TT.

## Examples

### Headers

This snippet:
````
=h= Header 1
    =h= Header 2
        =h= Header 3
    =h= Another H2
        =h= Another H3
=h= Another H1
````

Will generate:

````HTML
<h1>Header 1</h1>
<h2>Header 2</h2>
<h3>Header 3</h3>
<h2>Another H2</h2>
<h3>Another H3</h3>
<h1>Another H1</h1>
````
And will look like this:

> <h1>Header 1</h1>
> <h2>Header 2</h2>
> <h3>Header 3</h3>
> <h2>Another H2</h2>
> <h3>Another H3</h3>
> <h1>Another H1</h1>

## Grammar [In-Progress]
The following is an modified EBNF grammar for TimberText.

TERMINAL = '\n' ;
NONZERO = REGEX [1-9] ;
DIGIT = '0' | NONZERO ;
ALPHA = REGEX [a-zA-Z] ;
CHARACTER = ALPHA | DIGIT ;
WORD = CHARACTER , WORD | CHARACTER , TERMINAL ; 
TITLE = WORD , ' ' , TITLE | WORD , TERMINAL ;

HEADER = { "=" , { NONZERO | 'h' } , "=" } , TITLE , TERMINAL ;
