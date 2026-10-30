#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
#import "Program_Print";
#import "Sort";
#import "Process";

Markdown :: #import "Markdown";

OPEN_TAG :: "<?jai";
CLOSE_TAG :: "?>";
BUILD_DIR :: "public/";

// Members are read from the frontmatter key with the same name, except the ones marked @NoFrontmatter
Post :: struct {
	title: string;
	slug: string;
	pub_date_time: Calendar_Time;
	updated_date_time: Calendar_Time; // Optional, only set when the post was revised after its publication
	tags: [] string;
	description: string;
	bluesky_url: string;
	html: string; @NoFrontmatter
	head_html: string; @NoFrontmatter // Elements added to the <head> of the page, used by the Typst pages
}

Project :: struct {
	title: string;
	slug: string;
	pub_date_time: Calendar_Time;
	description: string;
	hero_image: string;
	hero_image_alt: string;
	team_size: int;
	time_frame: string;
	tools_used: string;
	html: string; @NoFrontmatter
	head_html: string; @NoFrontmatter // Elements added to the <head> of the page, used by the Typst pages
	repo: string;
	itch: string;
	featured: bool; // Featured projects are the ones shown on the index
}

posts :: #run load_entries(Post, "posts");
projects :: #run load_entries(Project, "projects");
featured_projects :: #run -> [] Project {
	result: [..] Project;
	for projects if it.featured then array_add(*result, it);
	return result;
};

INDEX_POST_COUNT :: 4; // Number of recent posts shown on the index

// Blogs shown at the bottom of the index, displayed by their domain name
BLOGROLL :: string.[
	"https://sebdegraff.com/blog.html",
	"https://jakubtomsu.github.io/",
	"https://aras-p.info/",
	"https://zylinski.se/",
	"https://zeux.io/",
	"https://blog.voxagon.se/",
	"https://www.gingerbill.org/",
	"https://fgiesen.wordpress.com/",
	"https://floooh.github.io/",
	"https://momentsingraphics.de/index.html",
	"https://rxi.github.io/",
];

// Returns the domain name of a URL (e.g. "https://example.com/blog.html" -> "example.com")
url_domain :: (url: string) -> string {
	has_scheme, _, after_scheme := split_from_left(url, "://");
	domain := ifx has_scheme then after_scheme else url;
	_, domain = split_from_left(domain, #char "/");
	return domain;
}

// Entries shown by projects_list.jaitml and posts_list.jaitml, set by the page including them
listed_projects: [] Project;
listed_posts: [] Post;

// Parses every Markdown and Typst file in src/<folder>, and returns them sorted from newest to oldest
load_entries :: ($T: Type, folder: string) -> [] T {
	Visit_Data :: struct {
		entries: [..] T;
		documents: [..] *Markdown.Ast_Node; // documents[i] is the parsed markdown of entries[i], or null if it was written in Typst
		folder: string;
	}

	data := Visit_Data.{folder = folder};
	visit_files(tprint("src/%", folder), false, *data, (info: *File_Visit_Info, data: *Visit_Data) {
		ext, ok := path_extension(info.short_name);
		if !ok then return;

		entry: T;
		node: *Markdown.Ast_Node;
		if ext == {
			case "md";
				log("Parsing %", info.short_name);
				markdown_file_contents := read_entire_file(info.full_name);
				node = Markdown.parse(markdown_file_contents);
				entry = parse_frontmatter(T, node.content, info.short_name);
			case "typ";
				log("Compiling %", info.short_name);
				entry = load_typst_entry(T, info.full_name, info.short_name);
			case;
				return;
		}

		make_directory_if_it_does_not_exist(tprint("%1%2/%3", BUILD_DIR, data.folder, entry.slug));
		array_add(*data.entries, entry);
		array_add(*data.documents, node);
	});

	// Highlight all the code blocks at once, so Bun only has to start once
	code_blocks: [..] Highlighted_Block;
	for data.documents if it then find_markdown_code_blocks(it, *code_blocks);
	for data.entries if !data.documents[it_index] then find_typst_code_blocks(it.html, it_index, *code_blocks);
	highlight_code_blocks(code_blocks);
	for * data.entries {
		document := data.documents[it_index];
		if document then it.html = Markdown.emit_html(document);
		else it.html = replace_typst_code_blocks(it.html, it_index, code_blocks);
	}

	return quick_sort(data.entries, (a: T, b: T) -> int {
		return compare_apollo_times(calendar_to_apollo(b.pub_date_time), calendar_to_apollo(a.pub_date_time));
	});
}

TYPST_PAGE :: "src/typst_page.typ";
TYPST_ENDNOTES_START :: "<section role=\"doc-endnotes\">";

// Compiles a Typst file to HTML with the Typst CLI, through TYPST_PAGE which applies the show rules of the website.
// The frontmatter is the "key: value" lines of the /* */ comment at the start of the file.
load_typst_entry :: ($T: Type, path: string, file_name: string) -> T {
	contents := trim_left(read_entire_file(path));
	frontmatter := "";
	if starts_with(contents, "/*") {
		frontmatter_end := find_index_from_left(contents, "*/");
		if frontmatter_end >= 0 then frontmatter = slice(contents, 2, frontmatter_end - 2);
	}
	if frontmatter.count == 0 then log_error("%: the file doesn't start with a /* */ comment containing the frontmatter", file_name);
	entry := parse_frontmatter(T, frontmatter, file_name);

	result, output, error := run_command(
		"typst", "compile", "--features", "html", "--format", "html", "--root", ".",
		"--input", tprint("path=/%", path), TYPST_PAGE, "-",
		capture_and_return_output = true
	);
	if result.type != .EXITED || result.exit_code != 0 {
		log_error("%: couldn't compile the file with Typst (is Typst installed?)\n%", file_name, error);
		return entry;
	}

	// Typst always warns that its HTML export is experimental, only show the output if there are other warnings
	first_warning := find_index_from_left(error, "warning:");
	if first_warning >= 0 && find_index_from_left(error, "warning:", first_warning + 1) >= 0 then log("%", error);

	body_start := find_index_from_left(output, "<body>");
	body_end := find_index_from_right(output, "</body>");
	if body_start < 0 || body_end < body_start {
		log_error("%: couldn't find the <body> in the output of Typst", file_name);
		return entry;
	}
	body_start += "<body>".count;
	entry.html = slice(output, body_start, body_end - body_start);

	// The footnotes are shown as sidenotes by TYPST_PAGE, so remove the list of footnotes at the end of the page
	endnotes_start := find_index_from_left(entry.html, TYPST_ENDNOTES_START);
	if endnotes_start >= 0 {
		endnotes_end := find_index_from_left(entry.html, "</section>", endnotes_start);
		if endnotes_end >= 0 {
			endnotes_end += "</section>".count;
			entry.html = join(slice(entry.html, 0, endnotes_start), slice(entry.html, endnotes_end, entry.html.count - endnotes_end));
		}
	}

	// Keep the styles of the <head>, Typst uses them for the MathML equations
	head := slice(output, 0, body_start);
	head_html: String_Builder;
	while true {
		style_start := find_index_from_left(head, "<style>");
		if style_start < 0 then break;
		style_end := find_index_from_left(head, "</style>", style_start);
		if style_end < 0 then break;
		style_end += "</style>".count;
		append(*head_html, slice(head, style_start, style_end - style_start));
		advance(*head, style_end);
	}
	entry.head_html = builder_to_string(*head_html);

	return entry;
}

// A code block to highlight with highlight_code_blocks
Highlighted_Block :: struct {
	language: string;
	code: string;
	html: string; // Highlighted HTML, stays empty if the highlighting failed

	markdown_node: *Markdown.Ast_Node; // Only set for the Markdown blocks, which are replaced in their node
	typst_entry_index: int; // The Typst blocks are replaced in the html of their entry, at [typst_start, typst_end[
	typst_start: int;
	typst_end: int;
}

find_markdown_code_blocks :: (document: *Markdown.Ast_Node, code_blocks: *[..] Highlighted_Block) {
	node := document.first_child;
	while node {
		if node.kind == .CodeBlock {
			code := ifx node.first_child then node.first_child.content else "";
			array_add(code_blocks, .{language = node.content, code = code, markdown_node = node});
		}
		node = node.next_sibling;
	}
}

// Emitted by the show rule of TYPST_PAGE for the code blocks
TYPST_CODE_BLOCK_START :: "<pre><code data-lang=\"";
TYPST_CODE_BLOCK_END :: "</code></pre>";

find_typst_code_blocks :: (html: string, entry_index: int, code_blocks: *[..] Highlighted_Block) {
	start := find_index_from_left(html, TYPST_CODE_BLOCK_START);
	while start >= 0 {
		language_start := start + TYPST_CODE_BLOCK_START.count;
		language_end := find_index_from_left(html, "\">", language_start);
		end := find_index_from_left(html, TYPST_CODE_BLOCK_END, language_start);
		if language_end < 0 || end < 0 then return;
		code_start := language_end + 2;

		block: Highlighted_Block;
		block.language = slice(html, language_start, language_end - language_start);
		block.code = unescape_html(slice(html, code_start, end - code_start));
		block.typst_entry_index = entry_index;
		block.typst_start = start;
		block.typst_end = end + TYPST_CODE_BLOCK_END.count;
		array_add(code_blocks, block);

		start = find_index_from_left(html, TYPST_CODE_BLOCK_START, block.typst_end);
	}
}

replace_typst_code_blocks :: (html: string, entry_index: int, code_blocks: [] Highlighted_Block) -> string {
	result: String_Builder;
	cursor := 0;
	for code_blocks {
		if it.markdown_node || it.typst_entry_index != entry_index || it.html.count == 0 then continue;
		append(*result, slice(html, cursor, it.typst_start - cursor));
		append(*result, it.html);
		cursor = it.typst_end;
	}
	append(*result, slice(html, cursor, html.count - cursor));
	return builder_to_string(*result);
}

// Typst escapes the text of the code blocks, but highlight.js needs the original code
unescape_html :: (text: string) -> string {
	result := replace(text, "&lt;", "<");
	result = replace(result, "&gt;", ">");
	result = replace(result, "&quot;", "\"");
	result = replace(result, "&#39;", "'");
	return replace(result, "&amp;", "&");
}

HIGHLIGHT_INPUT  :: ".build/highlight_input.txt";
HIGHLIGHT_OUTPUT :: ".build/highlight_output.txt";

// Highlights the code blocks with highlight.js at build time, by running tools/highlight/highlight.js with Bun.
// Each Markdown code block is replaced by an HTML block containing the highlighted code, so the pages don't need any JS for it.
highlight_code_blocks :: (code_blocks: [] Highlighted_Block) {
	if code_blocks.count == 0 then return;

	// Each block is written as "<language>\n<code byte count>\n<code>"
	input: String_Builder;
	for code_blocks print_to_builder(*input, "%\n%\n%", it.language, it.code.count, it.code);
	make_directory_if_it_does_not_exist(".build");
	write_entire_file(HIGHLIGHT_INPUT, *input);

	result, output, error := run_command("bun", "tools/highlight/highlight.js", HIGHLIGHT_INPUT, HIGHLIGHT_OUTPUT, capture_and_return_output = true);
	if result.type != .EXITED || result.exit_code != 0 {
		log_error("Couldn't highlight the code blocks with Bun, they will be left as plain text (is Bun installed?)\n%", error);
		return;
	}

	highlighted, ok := read_entire_file(HIGHLIGHT_OUTPUT);
	if !ok {
		log_error("Couldn't read the highlighted code blocks from %", HIGHLIGHT_OUTPUT);
		return;
	}

	// The output contains "<html byte count>\n<html>" for each block, in the same order
	for * code_blocks {
		newline := find_index_from_left(highlighted, #char "\n");
		if newline < 0 {
			log_error("The output of the highlighter is missing some code blocks");
			return;
		}
		byte_count := to_integer(slice(highlighted, 0, newline));
		advance(*highlighted, newline + 1);
		html := slice(highlighted, 0, byte_count);
		advance(*highlighted, byte_count);

		language := ifx it.language.count > 0 then it.language else "plaintext";
		it.html = sprint("<pre><code class=\"hljs language-%\">%</code></pre>", escape(language), html);

		node := it.markdown_node;
		if node {
			node.kind = .HtmlBlock;
			node.content = it.html;
			node.first_child = null;
			node.last_child = null;
		}
	}
}

SITE_NAME :: "Fabian Huber";
SITE_URL :: "https://fabianhbr.ch";
DEFAULT_DESCRIPTION :: "Website of Fabian Huber. Presentation of my projects and blog posts.";

// Metadata of the page being generated, used by header.jaitml
title := "";
og_title := "";
description := "";
page_url := "";
og_type := "";
og_image := "";
og_image_alt := "";
og_published_time: Calendar_Time; // Only set for articles, see is_date_set
og_modified_time: Calendar_Time;
head_html := ""; // Inserted as is at the end of the <head>

set_page_meta :: (
	page_title: string,
	path: string,
	page_description := "",
	type := "website",
	image := "",
	image_alt := "",
	published_time := Calendar_Time.{},
	modified_time := Calendar_Time.{},
	page_head_html := ""
) {
	og_title = page_title;
	title = ifx page_title == SITE_NAME then SITE_NAME else tprint("% - %", page_title, SITE_NAME);
	description = ifx page_description.count > 0 then page_description else DEFAULT_DESCRIPTION;
	page_url = tprint("%1%2", SITE_URL, path);
	og_type = type;
	og_image = ifx image.count > 0 then tprint("%1%2", SITE_URL, image) else "";
	og_image_alt = image_alt;
	og_published_time = published_time;
	og_modified_time = modified_time;
	head_html = page_head_html;
}

// Used by the templates to escape values before inserting them in the HTML
escape :: (text: string) -> string {
	return Markdown.escape_for_html(text);
}

// Fills the members of T whose name matches a frontmatter key (e.g. "hero_image: ..." -> hero_image)
parse_frontmatter :: ($T: Type, frontmatter: string, file_name: string) -> T {
	result: T;
	info := type_info(T);

	for line: split(frontmatter, "\n") {
		if trim(line).count == 0 then continue;

		found, key, value := split_from_left(line, ": ");
		if !found {
			log_error("%: invalid frontmatter line, expected 'key: value' (line: %)", file_name, line);
			continue;
		}
		value = trim(value);

		member := find_frontmatter_member(info, key);
		if !member {
			log_error("%: unknown frontmatter key (key: %, value: %)", file_name, key, value);
			continue;
		}

		address := (cast(*u8) *result) + member.offset_in_bytes;
		if member.type == {
			case type_info(string);
				(cast(*string) address).* = value;
			case type_info(int);
				(cast(*int) address).* = to_integer(value);
			case type_info(bool);
				if value != "true" && value != "false" {
					log_error("%: invalid boolean, expected true or false (key: %, value: %)", file_name, key, value);
					continue;
				}
				(cast(*bool) address).* = value == "true";
			case type_info([] string);
				(cast(*[] string) address).* = split(value, ", ");
			case type_info(Calendar_Time);
				// Dates are written as YYYY-MM-DD
				date := split(value, "-");
				if date.count != 3 {
					log_error("%: invalid date, expected YYYY-MM-DD (key: %, value: %)", file_name, key, value);
					continue;
				}
				time := cast(*Calendar_Time) address;
				time.year = to_integer(date[0]).(s32);
				time.month_starting_at_0 = (to_integer(date[1]) - 1).(s8);
				time.day_of_month_starting_at_0 = (to_integer(date[2]) - 1).(s8);
			case;
				log_error("%: frontmatter key '%' maps to a member of unsupported type %", file_name, key, member.type.type);
		}
	}

	return result;
}

find_frontmatter_member :: (info: *Type_Info_Struct, key: string) -> *Type_Info_Struct_Member {
	for * member: info.members {
		if member.name != key continue;
		for member.notes if it == "NoFrontmatter" return null;
		return member;
	}
	return null;
}

// Formats a date as YYYY-MM-DD, used both for display and for the datetime attribute of <time>
format_date :: (ct: Calendar_Time) -> string {
	two_digits :: #bake_arguments formatInt(minimum_digits = 2);
	return tprint("%-%-%", ct.year, two_digits(ct.month_starting_at_0 + 1), two_digits(ct.day_of_month_starting_at_0 + 1));
}

// A Calendar_Time that wasn't set in the frontmatter is zeroed
is_date_set :: (ct: Calendar_Time) -> bool {
	return ct.year != 0;
}

// RSS 2.0 requires dates in the RFC 822 format (e.g. "Sat, 25 Jul 2026 00:00:00 GMT")
calendar_to_rfc822_string :: (ct: Calendar_Time) -> string {
	DAY_NAMES :: string.["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
	MONTH_NAMES :: string.["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	// The frontmatter only sets the date, so round-trip through Apollo_Time to get the day of the week
	utc := to_calendar(calendar_to_apollo(ct), .UTC);
	two_digits :: #bake_arguments formatInt(minimum_digits = 2);
	result := tprint("%, % % % %:%:% GMT",
		DAY_NAMES[utc.day_of_week_starting_at_0],
		two_digits(utc.day_of_month_starting_at_0 + 1),
		MONTH_NAMES[utc.month_starting_at_0], utc.year,
		two_digits(utc.hour),
		two_digits(utc.minute),
		two_digits(utc.second)
	);
	return result;
}

render_jaitml :: (path: string) -> string {
	content, ok := read_entire_file(path);
	if !ok return "";

	code := false;
	sb: String_Builder;
	result: String_Builder;

	i := 0;
	while i < content.count {
		s := slice(content, i, content.count - 1);
		if !code {
			if starts_with(s, OPEN_TAG) {
				str := builder_to_string(*sb);
				if str != "" then print_to_builder(*result, "append(*jaitml_string_builder, \"%\");\n", str);
				code = true;
				i += OPEN_TAG.count;
			} else {
				if content[i] == {
					case "\n"; append(*sb, "\\n");
					case "\r"; append(*sb, "\\r");
					case "\t"; append(*sb, "\\t");
					case "\\"; append(*sb, "\\\\");
					case "\""; append(*sb, "\\\"");
					case; append(*sb, content[i]);
				}
				i += 1;
			}
		} else {
			if starts_with(s, CLOSE_TAG) {
				print_to_builder(*result, "%\n", builder_to_string(*sb));
				code = false;
				i += CLOSE_TAG.count;
			} else {
				append(*sb, content[i]);
				i += 1;
			}
		}
	}

	str := builder_to_string(*sb);
	if str != "" {
		if !code then print_to_builder(*result, "append(*jaitml_string_builder, \"%\");\n", str);
		else print_to_builder(*result, "%\n", str);
	}

	return builder_to_string(*result);
}

execute_jaitml :: ($path: string, output_path: string, $extra_code: Code = #code {}) #expand {
	jaitml_string_builder: String_Builder;
	echo :: (format_string: string, args: ..Any) #expand {
		print_to_builder(*jaitml_string_builder, format_string, ..args);
	}
	include :: (include_path: string) #expand {
		sub_file_path_string :: #run -> string {
			sub_file_path := parse_path(path);
			sub_file_path.words[sub_file_path.words.count - 1] = include_path;
			return path_to_string(sub_file_path);
		}

		sub_code :: #run render_jaitml(sub_file_path_string);
		#insert,scope() sub_code;
	}

	#insert,scope() -> Code {
		statements_to_insert: [..] *Code_Node;

		extra_code_nodes := compiler_get_nodes(extra_code);
		if extra_code_nodes.kind == .BLOCK {
			block := extra_code_nodes.(*Code_Block);
			array_add(*statements_to_insert, ..block.statements);
		}

		file_code_nodes := compiler_get_nodes(#code {
			code :: #run render_jaitml(path);
			#insert,scope() code;
			write_entire_file(output_path, *jaitml_string_builder);
		});

		array_add(*statements_to_insert, file_code_nodes);

		block_to_insert := New(Code_Block);
		block_to_insert.block_type = .IMPERATIVE;
		block_to_insert.statements = statements_to_insert;
		return compiler_get_code(block_to_insert);
	}
}

#run {
	set_build_options_dc({do_output = false});

	make_directory_if_it_does_not_exist(BUILD_DIR);
	make_directory_if_it_does_not_exist(tprint("%posts", BUILD_DIR));
	make_directory_if_it_does_not_exist(tprint("%projects", BUILD_DIR));
	make_directory_if_it_does_not_exist(tprint("%about", BUILD_DIR));
	make_directory_if_it_does_not_exist(tprint("%subscribe", BUILD_DIR));

	#insert -> string {
		sb: String_Builder;
		for posts {
			print_to_builder(*sb, "set_page_meta(posts[%1].title, tprint(\"/posts/\%/\", posts[%1].slug), posts[%1].description, \"article\", published_time = posts[%1].pub_date_time, modified_time = posts[%1].updated_date_time, page_head_html = posts[%1].head_html);", it_index);
			print_to_builder(*sb, "execute_jaitml(\"src/post.html.jaitml\", tprint(\"\%posts/%/index.html\", BUILD_DIR), #code { POST_INDEX :: %; });", it.slug, it_index);
		}
		return builder_to_string(*sb);
	};

	#insert -> string {
		sb: String_Builder;
		for projects {
			print_to_builder(*sb, "set_page_meta(projects[%1].title, tprint(\"/projects/\%/\", projects[%1].slug), projects[%1].description, image = projects[%1].hero_image, image_alt = projects[%1].hero_image_alt, page_head_html = projects[%1].head_html);", it_index);
			print_to_builder(*sb, "execute_jaitml(\"src/project.html.jaitml\", tprint(\"\%projects/%/index.html\", BUILD_DIR), #code { PROJECT_INDEX :: %; });", it.slug, it_index);
		}
		return builder_to_string(*sb);
	};

	set_page_meta(SITE_NAME, "/");
	execute_jaitml("src/index.html.jaitml", tprint("%index.html", BUILD_DIR));
	set_page_meta("Posts", "/posts/");
	execute_jaitml("src/posts.html.jaitml", tprint("%posts/index.html", BUILD_DIR));
	set_page_meta("Projects", "/projects/");
	execute_jaitml("src/projects.html.jaitml", tprint("%projects/index.html", BUILD_DIR));
	set_page_meta("About", "/about/");
	execute_jaitml("src/about.html.jaitml", tprint("%about/index.html", BUILD_DIR));
	set_page_meta("Subscribe", "/subscribe/");
	execute_jaitml("src/subscribe.html.jaitml", tprint("%subscribe/index.html", BUILD_DIR));

	execute_jaitml("src/rss.xml.jaitml", tprint("%rss.xml", BUILD_DIR));
}
