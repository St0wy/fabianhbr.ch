
Node_Kind :: enum u8 {
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
	Strong;
	Emphasis;
	CodeInline;
	Link;
	Image;
	HtmlInline;
}

Node_Data :: union kind: Node_Kind {
	level: u8;
	content: string;
}

Ast_Node :: struct {
	parent: *Ast_Node;
	first_child: *Ast_Node;
	last_child: *Ast_Node;
	next_sibling: *Ast_Node;
	using data: Node_Data;
}

// document is the markdown file content
parse :: (document: string) -> root: *Ast_Node {
	root := parse_blocks(document);
	parse_inline(root);
	return root;
}

emit_html :: (root: *Ast_Node) -> string {
	print_open_tag :: (sb: *String_Builder, node: *Ast_Node) {
		if node.kind == {
			case .Document; // Do nothing
			case .Heading;
				print_to_builder(sb, "<h%>", node.level);
			case .Paragraph;
				append(sb, "<p>");
			case .Blockquote;
				append(sb, "<blockquote>");
			case .BulletList;
				append(sb, "<ul>");
			case .NumberList;
				append(sb, "<ol>");
			case .ListItem;
				append(sb, "<li>");
			case .CodeBlock;
				lang := ifx node.content.count > 0 then node.content else "plaintext";
				print_to_builder(sb, "<pre><code class=\"language-%\">", lang);
			case .ThematicBreak;
				append(sb, "<hr/>");
			case .HtmlInline; #through;
			case .HtmlBlock;
				append(sb, node.content);
			case .Text;
				append(sb, escape_for_html(node.content));
			case .Strong;
				append(sb, "<strong>");
			case .Emphasis;
				append(sb, "<em>");
			case .CodeInline;
				append(sb, "<code>");
			case .Link;
				print_to_builder(sb, "<a href=\"%\">", node.content);
			case .Image;
				print_to_builder(sb, "<img src=\"%\" alt=\"", node.content);
			case;
				log_error("Unhandled case in the html emitter open phase: %", node.*);
		}
	}

	print_close_tag :: (sb: *String_Builder, node: *Ast_Node) {
		if node.kind == {
			case .Heading;
				print_to_builder(sb, "</h%>", node.level);
			case .Paragraph;
				append(sb, "</p>");
			case .Blockquote;
				append(sb, "</blockquote>");
			case .BulletList;
				append(sb, "</ul>");
			case .NumberList;
				append(sb, "</ol>");
			case .ListItem;
				append(sb, "</li>");
			case .CodeBlock;
				append(sb, "</code></pre>");
			case .Strong;
				append(sb, "</strong>");
			case .Emphasis;
				append(sb, "</em>");
			case .CodeInline;
				append(sb, "</code>");
			case .Link;
				append(sb, "</a>");
			case .Image;
				append(sb, "\" />");
		}
	}

	if !root return "";
	sb: String_Builder;

	current := root;
	going_down := true;

	while current {
		if going_down {
			print_open_tag(*sb, current);
			if current.first_child {
				current = current.first_child;
				continue;
			}
		}

		print_close_tag(*sb, current);
		if current.next_sibling {
			current = current.next_sibling;
			going_down = true;
		} else {
			current = current.parent;
			going_down = false;
		}
	}

	return builder_to_string(*sb);
}

#scope_module

#import "Basic";
#import "Flat_Pool";
#import "String";

List_Level :: struct {
	list_node: *Ast_Node;
	last_item: *Ast_Node;
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

add_child :: inline (parent: *Ast_Node, child: *Ast_Node) {
	child.parent = parent;
	if parent.last_child then parent.last_child.next_sibling = child;
	else parent.first_child = child;
	parent.last_child = child;
}

// Inserts node right after sibling, so the inline nodes stay in the order of the text
insert_after :: inline (sibling: *Ast_Node, node: *Ast_Node) {
	node.parent = sibling.parent;
	node.next_sibling = sibling.next_sibling;
	sibling.next_sibling = node;
	if sibling.parent && sibling.parent.last_child == sibling then sibling.parent.last_child = node;
}

make_node :: inline (kind: Node_Kind, parent: *Ast_Node = null) -> *Ast_Node {
	node := New(Ast_Node,, a);
	node.kind = kind;
	if parent then add_child(parent, node);
	return node;
}

escape_for_html :: (text: string) -> string {
	sb: String_Builder;
	doc := text;
	while doc.count > 0 {
		if doc[0] == {
			case "&"; append(*sb, "&amp;");
			case "<"; append(*sb, "&lt;");
			case ">"; append(*sb, "&gt;");
			case "\""; append(*sb, "&quot;");
			case "'"; append(*sb, "&#39;");
			case; append(*sb, doc[0]);
		}
		advance(*doc);
	}

	return builder_to_string(*sb);
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

// Returns the current line without its newline, and advances doc to the start of the next line
take_line :: (doc: *string) -> string {
	line := doc.*;
	advance_to_newline(doc);
	line.count -= doc.count;
	if doc.count > 0 then advance(doc);
	return line;
}

peek_line :: inline (doc: string) -> string {
	d := doc;
	return take_line(*d);
}

is_blank :: inline (line: string) -> bool {
	return trim(line).count == 0;
}

// Returns the level of the heading (# to ######), or 0 if the line isn't a heading
heading_level :: (line: string) -> u8 {
	level := 0;
	while level < line.count && line[level] == "#" level += 1;
	if level == 0 || level > 6 || level >= line.count || line[level] != " " then return 0;
	return level.(u8);
}

// Returns the length of the list item marker ("- " or "12. "), or 0 if the line isn't an item of this kind of list
list_item_marker_length :: (line: string, kind: Node_Kind) -> int {
	if kind == .BulletList return ifx starts_with(line, "- ") then 2 else 0;

	digits := 0;
	while digits < line.count && is_digit(line[digits]) digits += 1;
	if digits == 0 || digits + 1 >= line.count || line[digits] != "." || line[digits + 1] != " " then return 0;
	return digits + 2;
}

is_list_item :: inline (line: string) -> bool {
	return list_item_marker_length(line, .BulletList) > 0 || list_item_marker_length(line, .NumberList) > 0;
}

// Checks if this line starts a new block and should therefore end the current paragraph
ends_paragraph :: (line: string) -> bool {
	return is_blank(line)
		|| heading_level(line) > 0
		|| starts_with(line, ">")
		|| starts_with(line, "---")
		|| starts_with(line, "```")
		|| is_list_item(line);
}

VOID_HTML_ELEMENTS :: string.["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"];

// Returns the length of the HTML element at the start of s (up to its closing tag), or -1 if its end couldn't be found
html_element_length :: (s: string) -> int {
	if starts_with(s, "<!--") {
		comment_end := find_index_from_left(s, "-->");
		return ifx comment_end < 0 then -1 else comment_end + 3;
	}

	name_end := 1;
	while name_end < s.count && !is_space(s[name_end]) && s[name_end] != ">" && s[name_end] != "/" name_end += 1;
	tag := slice(s, 1, name_end - 1);

	open_tag_end := find_index_from_left(s, ">", name_end);
	if open_tag_end < 0 then return -1;
	if s[open_tag_end - 1] == "/" then return open_tag_end + 1;
	for VOID_HTML_ELEMENTS if equal_nocase(tag, it) return open_tag_end + 1;

	is_tag_name_end :: (s: string, index: int) -> bool {
		return index < s.count && (is_space(s[index]) || s[index] == ">" || s[index] == "/");
	}

	// Count the nested elements with the same tag so they don't close this one early
	depth := 1;
	i := open_tag_end + 1;
	while i < s.count {
		rest := slice(s, i, s.count - i);
		if starts_with(rest, "</") && starts_with(advance(rest, 2), tag) && is_tag_name_end(rest, tag.count + 2) {
			depth -= 1;
			if depth == 0 {
				close_tag_end := find_index_from_left(s, ">", i);
				return ifx close_tag_end < 0 then -1 else close_tag_end + 1;
			}
		} else if starts_with(rest, "<") && starts_with(advance(rest, 1), tag) && is_tag_name_end(rest, tag.count + 1) {
			depth += 1;
		}
		i += 1;
	}

	return -1;
}

parse_blocks :: (document: string) -> *Ast_Node {
	if document.count == 0 then return null;

	a.proc = flat_pool_allocator_proc;
	a.data = *pool;

	doc := document;
	normalize_line_endings(*doc);

	root := make_node(.Document);

	// Parse frontmatter
	if starts_with(doc, "---") {
		rest := doc;
		take_line(*rest);
		frontmatter := rest;
		while rest.count > 0 && !starts_with(rest, "---") take_line(*rest);

		if rest.count > 0 {
			frontmatter.count -= rest.count;
			root.content = trim(frontmatter);
			take_line(*rest);
			doc = rest;
		} else {
			log_error("Markdown: the frontmatter doesn't have a closing '---', it will be parsed as regular Markdown");
		}
	}

	while doc.count > 0 {
		line := peek_line(doc);
		if is_blank(line) {
			take_line(*doc);
			continue;
		}

		indent, text := get_indent(line);

		if is_list_item(text) {
			// Lists handle the indentation themselves, to know how the items are nested
			kind := ifx list_item_marker_length(text, .BulletList) > 0 then Node_Kind.BulletList else .NumberList;
			parse_list(*doc, root, kind);
			continue;
		}

		// Other blocks ignore the indentation
		advance(*doc, text.data - doc.data);

		if heading_level(text) > 0 {
			level := heading_level(text);
			take_line(*doc);
			node := make_node(.Heading, parent=root);
			node.level = level;

			text_node := make_node(.Text, parent=node);
			text_node.content = trim(advance(text, level + 1));
		} else if text[0] == ">" {
			parse_blockquote(*doc, root);
		} else if starts_with(text, "```") {
			take_line(*doc);
			code_block := make_node(.CodeBlock, parent=root);
			code_block.content = trim(advance(text, 3));

			code := doc;
			while doc.count > 0 && !starts_with(doc, "```") take_line(*doc);
			code.count -= doc.count;
			if code.count > 0 && is_newline(code[code.count - 1]) then code.count -= 1; // Don't include the newline before the closing ```

			if doc.count > 0 {
				take_line(*doc);
			} else {
				log_error("Markdown: code block without a closing ```, it will continue until the end of the document");
			}

			text_node := make_node(.Text, parent=code_block);
			text_node.content = code;
		} else if text[0] == "<" {
			html_block := make_node(.HtmlBlock, parent=root);

			html := doc;
			length := html_element_length(html);
			if length < 0 {
				log_error("Markdown: couldn't find the end of the HTML block \"%\", it will end at the next empty line", text);
				rest := doc;
				while rest.count > 0 && !is_blank(peek_line(rest)) take_line(*rest);
				length = doc.count - rest.count;
			}

			// Keep what follows the element on the same line
			line_rest := peek_line(advance(html, length));
			if !is_blank(line_rest) then length += line_rest.count;

			html.count = length;
			if html.count > 0 && is_newline(html[html.count - 1]) then html.count -= 1;
			html_block.content = html;

			advance(*doc, length);
			take_line(*doc);
		} else if starts_with(text, "---") {
			take_line(*doc);
			make_node(.ThematicBreak, parent=root);
		} else {
			par_node := make_node(.Paragraph, parent=root);
			par_content := doc;
			take_line(*doc);
			while doc.count > 0 && !ends_paragraph(peek_line(doc)) take_line(*doc);

			par_content.count -= doc.count;
			if par_content.count > 0 && is_newline(par_content[par_content.count - 1]) then par_content.count -= 1;

			text_node := make_node(.Text, parent=par_node);
			text_node.content = par_content;
		}
	}

	return root;
}

parse_blockquote :: (doc: *string, root: *Ast_Node) {
	quote_node := make_node(.Blockquote, parent=root);

	lines: [..] string;
	lines.allocator = a;

	// Each paragraph is a single text node, so inline elements can span multiple lines
	add_paragraph :: () #expand {
		if lines.count == 0 then return;
		par_node := make_node(.Paragraph, parent=quote_node);
		text_node := make_node(.Text, parent=par_node);
		text_node.content = join(..lines, "\n",, a);
		array_reset_keeping_memory(*lines);
	}

	while doc.count > 0 {
		line := trim_left(peek_line(doc.*), " \t");
		if !starts_with(line, ">") then break;
		take_line(doc);

		text := trim(advance(line, 1));
		if text.count > 0 {
			array_add(*lines, text);
		} else {
			// An empty line in a blockquote separates two paragraphs
			add_paragraph();
		}
	}

	add_paragraph();
}

parse_list :: (doc: *string, root: *Ast_Node, kind: Node_Kind) {
	stack: [MAX_SUBLISTS_COUNT] List_Level;
	count := 1;

	first_indent := get_indent(peek_line(doc.*));
	stack[0] = .{make_node(kind, parent=root), null, first_indent};

	while doc.count > 0 {
		item_indent, text := get_indent(peek_line(doc.*));
		marker_length := list_item_marker_length(text, kind);
		if marker_length == 0 then break;
		take_line(doc);

		while count > 1 && item_indent <= stack[count - 2].indent {
			count -= 1;
		}

		top := *stack[count - 1];

		// Items that are more indented start a sub-list, unless we already reached the maximum depth
		if item_indent > top.indent && top.last_item && count < MAX_SUBLISTS_COUNT {
			sub_list := make_node(kind, parent=top.last_item);
			stack[count] = .{sub_list, null, item_indent};
			count += 1;
			top = *stack[count - 1];
		}

		list_item_node := make_node(.ListItem, parent=top.list_node);
		top.last_item = list_item_node;

		// Indented lines that aren't list items continue the text of this item
		item_text := trim(advance(text, marker_length));
		while doc.count > 0 {
			next_line := peek_line(doc.*);
			next_indent, next_text := get_indent(next_line);
			if is_blank(next_line) || next_indent <= stack[0].indent || is_list_item(next_text) then break;
			take_line(doc);
			item_text = join(item_text, trim(next_text), separator="\n",, a);
		}

		text_node := make_node(.Text, parent=list_item_node);
		text_node.content = item_text;
	}
}

parse_inline :: (node: *Ast_Node) {
	parent_is_code := ifx node.parent && node.parent.kind == .CodeBlock then true else false;
	if node.kind == .Text && !parent_is_code {
		doc := node.content;
		previous_char: u8;
		while doc.count > 0 {
			is_strong := starts_with(doc, "**");
			is_em := doc[0] == "_";
			is_code := doc[0] == "`";
			if !is_alnum(previous_char) && (is_strong || is_em || is_code) {
				start_doc := doc;
				kind := ifx is_strong then Node_Kind.Strong else ifx is_em then Node_Kind.Emphasis else ifx is_code then Node_Kind.CodeInline;
				advance(*doc, ifx is_strong then 2 else 1);
				content := doc;
				found_closing_symbol := false;
				while doc.count > 0 {
					close_strong := is_strong && starts_with(doc, "**");
					close_em := is_em && doc[0] == "_";
					close_code := is_code && doc[0] == "`";
					if close_strong || close_em || close_code {
						found_closing_symbol = true;
						offset := ifx close_strong 2 else 1;
						if doc.count > offset && is_alnum(doc[offset]) {
							found_closing_symbol = false;
						}
						if found_closing_symbol then break;
					}
					advance(*doc);
				}

				if found_closing_symbol {
					content.count -= doc.count;
					advance(*doc, ifx is_strong then 2 else 1);

					node.content.count -= start_doc.count;
					parent_node := make_node(kind);
					insert_after(node, parent_node);
					text_node := make_node(.Text, parent=parent_node);
					text_node.content = content;

					if doc.count > 0 {
						rest_of_text_node := make_node(.Text);
						insert_after(parent_node, rest_of_text_node);
						rest_of_text_node.content = doc;
					}

					break;
				}

				doc = start_doc;
			} else if doc[0] == "[" || (doc.count > 1 && starts_with(doc, "![")) {
				is_image := doc[0] == "!";
				start_doc := doc;
				advance(*doc, ifx is_image 2 else 1);

				link_text := doc;
				found_closing_brackets := false;
				while doc.count > 0 {
					if doc[0] == "]" {
						found_closing_brackets = true;
						break;
					}
					advance(*doc);
				}

				if found_closing_brackets && doc.count > 1 && doc[1] == "(" {
					link_text.count -= doc.count;
					advance(*doc, 2);

					link_url := doc;
					found_closing_paren := false;
					while doc.count > 0 {
						if doc[0] == ")" {
							found_closing_paren = true;
							break;
						}
						advance(*doc);
					}

					if found_closing_paren {
						link_url.count -= doc.count;
						advance(*doc);

						node.content.count -= start_doc.count;
						kind := ifx is_image then Node_Kind.Image else Node_Kind.Link;
						link_node := make_node(kind);
						insert_after(node, link_node);
						link_node.content = link_url;

						link_text_node := make_node(.Text, parent=link_node);
						link_text_node.content = link_text;

						if doc.count > 0 {
							rest_of_text_node := make_node(.Text);
							insert_after(link_node, rest_of_text_node);
							rest_of_text_node.content = doc;
						}

						break;
					}
				}

				doc = start_doc;
			} else if doc[0] == "<" {
				start_doc := doc;
				html_string := doc;

				advance(*doc);
				tag := doc;
				found_open_tag_closing_chevron := false;
				while doc.count > 0 {
					found_open_tag_closing_chevron = doc[0] == ">";
					if found_open_tag_closing_chevron || is_space(doc[0]) {
						tag.count -= doc.count;
						break;
					}

					advance(*doc);
				}

				if found_open_tag_closing_chevron {
					open_count := 1;
					while doc.count > 0 && open_count > 0 {
						if starts_with(doc, tprint("<%>", tag)) open_count += 1;
						if starts_with(doc, tprint("</%>", tag)) open_count -= 1;
						advance(*doc);
					}

					foud_close_tag_closing_chevron := false;
					while doc.count > 0 {
						if doc[0] == ">" {
							foud_close_tag_closing_chevron = true;
							advance(*doc);
							break;
						}

						advance(*doc);
					}
					if foud_close_tag_closing_chevron {
						html_string.count -= doc.count;
						node.content.count -= start_doc.count;
						html_block := make_node(.HtmlInline);
						insert_after(node, html_block);
						html_block.content = html_string;

						if doc.count > 0 {
							rest_of_text_node := make_node(.Text);
							insert_after(html_block, rest_of_text_node);
							rest_of_text_node.content = doc;
						}

						break;
					}
				}

				doc = start_doc;
			}

			previous_char = doc[0];
			advance(*doc);
		}
	}

	child := node.first_child;
	while child {
		parse_inline(child);
		child = child.next_sibling;
	}
}
