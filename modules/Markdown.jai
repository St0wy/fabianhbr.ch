
NodeType :: enum u8 {
	Document;
	Heading;
	Paragraph;
	Blockquote;
	List;
	ListItem;

	Text;
	Strong;
	Emphasis;
	CodeInline;
	Link;
	Image;
}

Link :: struct {
	url: string;
	title: string;
}

NodeData :: union type: NodeType {
	.Document,, frontmatter: string;
	.Heading,, level: u8;
	.Text,, content: string;
	.Link,, link: Link;
	.Image,, link: Link;
}

AstNode :: struct {
	parent: *AstNode;
	first_child: *AstNode;
	last_child: *AstNode;
	next_sibling: *AstNode;
	using data: NodeData;
}

// document is the mardown file content with frontmatter if there is one
parse_block :: (document: string) -> *AstNode {
	doc := document;

	if starts_with(doc, "---") {
		skip_line(*doc);

	}
	while document.count > 0 {
		if
	}
}

#scope_module

#import "Flat_Pool";
#import "String";

pool: Flat_Pool;

is_newline :: inline (c: u8) -> bool {
	return c == "\n";
}

skip_line :: inline (str: *string) {
	c := str.*[0];
	advance(str);
	while !is_newline(c) {
		c = str.*[0];
		advance(str);
	}
}

// Thing :: union fruit: Fruit {
//     .APPLE  ,, x: int;
//     .BANANA ,, y: float;
//     .ORANGE ,, z := "You're ruining Hamlet!";
// }
// Value :: union kind: Value_Kind {
//     scalar: float64;
//     vector: Vector4;
//     _string: string;
// }
