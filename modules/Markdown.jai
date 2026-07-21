
NodeKind :: enum u8 {
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

NodeData :: union kind: NodeKind {
	frontmatter: string;
	level: u8;
	content: string;
	link: Link;
}

AstNode :: struct {
	parent: *AstNode;
	first_child: *AstNode;
	last_child: *AstNode;
	next_sibling: *AstNode;
	using data: NodeData;
}

// document is the mardown file content with frontmatter if there is one
parse_blocks :: (document: string) -> *AstNode {
	if document.count == 0 then return null;

	a: Allocator;
	a.proc = flat_pool_allocator_proc;
	a.data = *pool;

	doc := document;
	normalize_line_endings(*doc);

	root := New(AstNode,, a);
	root.kind = .Document;

	// Parse frontmatter
	if starts_with(doc, "---") {
		skip_line(*doc);
		frontmatter := doc;
		while !starts_with(doc, "---") skip_line(*doc);
		end_frontmatter := doc;
		frontmatter.count -= end_frontmatter.count;
		root.frontmatter = trim(frontmatter);
		skip_line(*doc);
	}

	while doc.count > 0 {
		if doc[0] == "#" {
			node := New(AstNode,, a);
			node.kind = .Heading;
			heading_level: u8;
			while doc[0] == "#" {
				advance(*doc);
				heading_level += 1;
			}
			assert(doc[0] == " ");
			advance(*doc);
			node.level = heading_level;

			text := doc;
			advance_to_newline(*doc);
			text.count -= doc.count;

			text_node := New(AstNode,, a);
			text_node.kind = .Text;
			text_node.content = trim(text);
			add_child(node, text_node);
			add_child(root, node);
		} else if doc[0] == ">" {
			quote_node := New(AstNode,, a);
			quote_node.kind = .Blockquote;

			advance(*doc);
			trim_left(*doc, " \t");

			text := doc;
			advance_to_newline(*doc);
			text.count -= doc.count;

			par_node
		} else if !is_newline(doc[0]) {
			par := doc;
			while doc.count > 0 {
				advance_to_newline(*doc);
				if doc.count > 0 {
					peek := doc;
					advance(*peek);
					if peek.count == 0 || is_newline(peek[0]) then break;
					if peek[0] == "#" then break;
					advance(*doc);
				}
			}
			par.count -= doc.count;

			par_node := New(AstNode,, a);
			par_node.kind = .Paragraph;

			text_node := New(AstNode,, a);
			text_node.kind = .Text;
			text_node.content = trim(par);

			add_child(par_node, text_node);
			add_child(root, par_node);
		}
		skip_line(*doc);
	}

	return root;
}

#scope_module

#import "Basic";
#import "Flat_Pool";
#import "String";

pool: Flat_Pool;

is_newline :: inline (c: u8) -> bool {
	return c == "\n";
}

advance_to_newline :: inline (str: *string) {
	while str.count > 0 && !is_newline(str.*[0]) advance(str);
}

// advance_to_empty_line :: inline (str: *string) {
// 	while str.count > 1 && !is_newline(str.*[0]) && !is_newline(str.*[1]) advance(str);
// 	advance(str);
// }

skip_line :: inline (str: *string) {
	if str.count == 0 then return;
	c := str.*[0];
	advance(str);
	while str.count > 0 && !is_newline(c) {
		c = str.*[0];
		advance(str);
	}
}

add_child :: (parent: *AstNode, child: *AstNode) {
	child.parent = parent;
	if parent.last_child then parent.last_child.next_sibling = child;
	else parent.first_child = child;
	parent.last_child = child;
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
