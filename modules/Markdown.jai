
NodeKind :: enum u8 {
	Document;

	// Blocks
	Heading;
	Paragraph;
	Blockquote;
	BulletList;
	NumberList;
	ListItem;
	ThematicBreak;
	CodeBlock;
	HtmlBlock;

// Inline
	Text;
	HtmlInline;
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

	a.proc = flat_pool_allocator_proc;
	a.data = *pool;

	doc := document;
	normalize_line_endings(*doc);

	root := make_node(.Document);

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
		indent:, doc = get_indent(doc);
		if doc[0] == "#" {
			node := make_node(.Heading, parent=root);
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

			text_node := make_node(.Text, parent=node);
			text_node.content = trim(text);
		} else if doc[0] == ">" {
			quote_node := make_node(.Blockquote, parent=root);
			par_node := make_node(.Paragraph, parent=quote_node);

			while doc.count > 0 && doc[0] == ">" {
				advance(*doc);
				doc = trim_left(doc, " \t");

				text := doc;
				advance_to_newline(*doc);
				text.count -= doc.count;
				text = trim(text);

				if text.count > 0 {
					// We have some text, so we add it to the paragraph
					text_node := make_node(.Text, parent=par_node);
					text_node.content = text;
				} else if par_node.first_child {
					// We have an empty blockquote line and the paragraph already has text, so we create a new paragraph
					// because empty text == new paragraph
					par_node = make_node(.Paragraph, parent=quote_node);
				}

				advance(*doc);
			}
		} else if doc.count > 1 && doc[0] == "-" && doc[1] == " " {
			stack: [MAX_SUBLISTS_COUNT] List_Level;
			count: u8 = 1;

			list_root := make_node(.BulletList, parent=root);
			stack[0] = {list_root, null, indent};

			while doc.count > 0 {
				item_indent:, doc = get_indent(doc);
				if doc.count == 0 || doc[0] != "-" then break;

				advance(*doc);
				doc = trim_left(doc, " \t");

				text := doc;
				advance_to_newline(*doc);
				text.count -= doc.count;

				while count > 1 && item_indent <= stack[count - 2].indent {
					count -= 1;
				}

				top := *stack[count - 1];

				if item_indent > top.indent && top.last_item {
					sub_list := make_node(.BulletList, parent=top.last_item);
					stack[count] = {sub_list, null, indent};
					count += 1;
					top = *stack[count - 1];
				}

				list_item_node := make_node(.ListItem, parent=top.list_node);
				top.last_item = list_item_node;

				text_node := make_node(.Text, parent=list_item_node);
				text_node.content = trim(text);

				if doc.count > 0 && is_newline(doc[0]) then advance(*doc);
			}
		} else if doc.count > 2 && is_digit(doc[0]) && doc[1] == "." && doc[2] == " " {
			// TODO Make this work with lists that are larger than 9 items
			// For now my markdown files don't have more than that, so it's okay
			// Also TODO make it possible to nest number lists inside bullet lists
			stack: [MAX_SUBLISTS_COUNT] List_Level;
			count: u8 = 1;

			list_root := make_node(.NumberList, parent=root);
			stack[0] = {list_root, null, indent};

			while doc.count > 0 {
				item_indent:, doc = get_indent(doc);
				if doc.count <= 1 || !is_digit(doc[0]) || doc[1] != "." then break;

				advance(*doc, 2);
				doc = trim_left(doc, " \t");

				text := doc;
				advance_to_newline(*doc);
				text.count -= doc.count;

				while count > 1 && item_indent <= stack[count - 2].indent {
					count -= 1;
				}

				top := *stack[count - 1];

				if item_indent > top.indent && top.last_item {
					sub_list := make_node(.NumberList, parent=top.last_item);
					stack[count] = {sub_list, null, indent};
					count += 1;
					top = *stack[count - 1];
				}

				list_item_node := make_node(.ListItem, parent=top.list_node);
				top.last_item = list_item_node;

				text_node := make_node(.Text, parent=list_item_node);
				text_node.content = trim(text);

				if doc.count > 0 && is_newline(doc[0]) then advance(*doc);
			}
		} else if starts_with(doc, "```") {
			advance(*doc, 3);

			lang := doc;
			advance_to_newline(*doc);
			lang.count -= doc.count;

			code_block := make_node(.CodeBlock, parent=root);
			code_block.content = lang;

			advance(*doc);

			text := doc;
			while !starts_with(doc, "```") skip_line(*doc);
			text.count -= doc.count + 1; // + 1 to not include the newline before the closing ```
			skip_line(*doc);

			text_node := make_node(.Text, parent=code_block);
			text_node.content = text;
		} else if doc[0] == "<" {
			html_block := make_node(.HtmlBlock, parent=root);
			html_string := doc;

			advance(*doc);
			tag := doc;
			while doc[0] != ">" && !is_space(doc[0]) advance(*doc);
			tag.count -= doc.count;
			open_count := 1;
			while doc.count > 0 && open_count > 0 {
				if starts_with(doc, tprint("<%>", tag)) open_count += 1;
				if starts_with(doc, tprint("</%>", tag)) open_count -= 1;
				advance(*doc);
			}
			while doc[0] != ">" advance(*doc);
			advance(*doc);

			html_string.count -= doc.count;
			html_block.content = html_string;
		} else if starts_with(doc, "---") {
			skip_line(*doc);
			thematic_break := make_node(.ThematicBreak, parent=root);
		}else if !is_newline(doc[0]) {
			par_node := make_node(.Paragraph, parent=root);
			while doc.count > 0 {
				line := doc;
				advance_to_newline(*doc);
				line.count -= doc.count;

				text_node := make_node(.Text, parent=par_node);
				text_node.content = trim(line);

				if doc.count > 0 {
					peek := doc;
					// Skip the \n
					advance(*peek);
					if peek.count == 0 || is_newline(peek[0]) then break;
					if peek[0] == "#" then break;
					if peek[0] == ">" then break;
					if peek[0] == "-" then break;
					advance(*doc);
				}
			}
		}

		skip_line(*doc);
	}

	return root;
}

emit_html :: (node: *AstNode) -> string {
	if !node then return "";
	sb: String_Builder;
	closing_tag: string;

	if node.kind == {
		case .Document; // Do nothing
		case .Heading;
			print_to_builder(*sb, "<h%>", node.level);
			closing_tag = tprint("</h%>", node.level);
		case .Paragraph;
			append(*sb, "<p>");
			closing_tag = "</p>";
		case .Blockquote;
			append(*sb, "<blockquote>");
			closing_tag = "</blockquote>";
		case .BulletList;
			append(*sb, "<ul>");
			closing_tag = "</ul>";
		case .NumberList;
			append(*sb, "<ol>");
			closing_tag = "</ol>";
		case .ListItem;
			append(*sb, "<li>");
			closing_tag = "</li>";
		case .CodeBlock;
			print_to_builder(*sb, "<pre><code class=\"language-%\">", node.content);
			closing_tag = "</code></pre>";
		case .ThematicBreak;
			append(*sb, "<hr/>");
			closing_tag = "";
		case .HtmlBlock;
			append(*sb, node.content);
			closing_tag = "";
		case .Text;
			append(*sb, escape_for_html(node.content));
			if node.next_sibling then append(*sb, " ");
		case;
			log_error("Unhandled case in the html emitter : %", node.*);
	}

	child := node.first_child;
	while child {
		append(*sb, emit_html(child));
		child = child.next_sibling;
	}

	append(*sb, closing_tag);

	return builder_to_string(*sb);
}

#scope_module

#import "Basic";
#import "Flat_Pool";
#import "String";

List_Level :: struct {
	list_node: *AstNode;
	last_item: *AstNode;
	indent: int;
}

pool: Flat_Pool;
a: Allocator;

MAX_SUBLISTS_COUNT :: 16;

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

add_child :: inline (parent: *AstNode, child: *AstNode) {
	child.parent = parent;
	if parent.last_child then parent.last_child.next_sibling = child;
	else parent.first_child = child;
	parent.last_child = child;
}

make_node :: inline (kind: NodeKind, parent: *AstNode = null) -> *AstNode {
	node := New(AstNode,, a);
	node.kind = kind;
	if parent then add_child(parent, node);
	return node;
}

escape_for_html :: (text: string) -> string {
	// TODO
	return text;
}

get_indent :: inline (s: string) -> indent: int, rest: string {
	indent := 0;
	str := s;
	while str.count > 0 {
		if str[0] == " " {
			indent += 1;
			advance(*str);
		} else if str[0] == "\t" {
			indent += 4;
			advance(*str);
		} else {
			break;
		}
	}

	return indent, str;
}
