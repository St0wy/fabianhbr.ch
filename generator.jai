#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
#import "Program_Print";
#import "Sort";

Markdown :: #import "Markdown";

OPEN_TAG :: "<?jai";
CLOSE_TAG :: "?>";
BUILD_DIR :: "public/";

// Members are read from the frontmatter key with the same name, except the ones marked @NoFrontmatter
Post :: struct {
	title: string;
	slug: string;
	pub_date_time: Calendar_Time;
	tags: [] string;
	description: string;
	bluesky_url: string;
	html: string; @NoFrontmatter
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
	repo: string;
	itch: string;
}

posts :: #run load_entries(Post, "posts");
projects :: #run load_entries(Project, "projects");

// Parses every markdown file in src/<folder>, and returns them sorted from newest to oldest
load_entries :: ($T: Type, folder: string) -> [] T {
	Visit_Data :: struct {
		entries: [..] T;
		folder: string;
	}

	data := Visit_Data.{folder = folder};
	visit_files(tprint("src/%", folder), false, *data, (info: *File_Visit_Info, data: *Visit_Data) {
		ext, ok := path_extension(info.short_name);
		if !ok || ext != "md" then return;

		log("Parsing %", info.short_name);
		markdown_file_contents := read_entire_file(info.full_name);
		node := Markdown.parse(markdown_file_contents);
		entry := parse_frontmatter(T, node.content, info.short_name);
		entry.html = Markdown.emit_html(node);
		make_directory_if_it_does_not_exist(tprint("%1%2/%3", BUILD_DIR, data.folder, entry.slug));
		array_add(*data.entries, entry);
	});

	return quick_sort(data.entries, (a: T, b: T) -> int {
		return compare_apollo_times(calendar_to_apollo(b.pub_date_time), calendar_to_apollo(a.pub_date_time));
	});
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

set_page_meta :: (page_title: string, path: string, page_description := "", type := "website", image := "", image_alt := "") {
	og_title = page_title;
	title = ifx page_title == SITE_NAME then SITE_NAME else tprint("% - %", page_title, SITE_NAME);
	description = ifx page_description.count > 0 then page_description else DEFAULT_DESCRIPTION;
	page_url = tprint("%1%2", SITE_URL, path);
	og_type = type;
	og_image = ifx image.count > 0 then tprint("%1%2", SITE_URL, image) else "";
	og_image_alt = image_alt;
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
			print_to_builder(*sb, "set_page_meta(posts[%1].title, tprint(\"/posts/\%/\", posts[%1].slug), posts[%1].description, \"article\");", it_index);
			print_to_builder(*sb, "execute_jaitml(\"src/post.html.jaitml\", tprint(\"\%posts/%/index.html\", BUILD_DIR), #code { POST_INDEX :: %; });", it.slug, it_index);
		}
		return builder_to_string(*sb);
	};

	#insert -> string {
		sb: String_Builder;
		for projects {
			print_to_builder(*sb, "set_page_meta(projects[%1].title, tprint(\"/projects/\%/\", projects[%1].slug), projects[%1].description, image = projects[%1].hero_image, image_alt = projects[%1].hero_image_alt);", it_index);
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
