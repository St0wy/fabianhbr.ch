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

Post :: struct {
	title: string;
	slug: string;
	pub_date_time: Calendar_Time;
	tags: [] string;
	description: string;
	html: string;
}

Project :: struct {
	title: string;
	slug: string;
	pub_date_time: Calendar_Time;
	description: string;
	hero_image: string;
	team_size: int;
	time_frame: string;
	tools_used: string;
	html: string;
}

posts :: #run -> [] Post {
	posts_arr: [..] Post;
	visit_files("src/posts", false, *posts_arr, (info: *File_Visit_Info, posts_arr: *[..] Post) {
		if info.is_directory then return;
		ext, ok := path_extension(info.short_name);
		if !ok then return;
		if ext != "md" then return;

		log("Parsing %", info.short_name);
		markdown_file_contents := read_entire_file(info.full_name);
		node := Markdown.parse(markdown_file_contents);
		html := Markdown.emit_html(node);
		post := parse_post_frontmatter(node.content);
		post.html = html;
		make_directory_if_it_does_not_exist(tprint("%posts/%", BUILD_DIR, post.slug));
		array_add(posts_arr, post);
	});
	sorted := quick_sort(posts_arr, (post_a: Post, post_b: Post) -> int {
		time_a := calendar_to_apollo(post_a.pub_date_time);
		time_b := calendar_to_apollo(post_b.pub_date_time);
		return compare_apollo_times(time_b, time_a);
	});
	return sorted;
}

projects :: #run -> [] Project {
	projects_arr: [..] Project;
	visit_files("src/projects", false, *projects_arr, (info: *File_Visit_Info, projects_arr: *[..] Project) {
		if info.is_directory then return;
		ext, ok := path_extension(info.short_name);
		if !ok then return;
		if ext != "md" then return;

		log("Parsing %", info.short_name);
		markdown_file_contents := read_entire_file(info.full_name);
		node := Markdown.parse(markdown_file_contents);
		html := Markdown.emit_html(node);
		project := parse_project_frontmatter(node.content);
		project.html = html;
		make_directory_if_it_does_not_exist(tprint("%projects/%", BUILD_DIR, project.slug));
		array_add(projects_arr, project);
	});
	sorted := quick_sort(projects_arr, (project_a: Project, project_b: Project) -> int {
		time_a := calendar_to_apollo(project_a.pub_date_time);
		time_b := calendar_to_apollo(project_b.pub_date_time);
		return compare_apollo_times(time_b, time_a);
	});
	return sorted;
}

title := "";

advance_to_newline :: inline (str: *string) {
	while str.count > 0 && str.*[0] != "\n" advance(str);
}
skip_line :: inline (str: *string) {
	if str.count == 0 then return;
	c := str.*[0];
	advance(str);
	while str.count > 0 && c != "\n" {
		c = str.*[0];
		advance(str);
	}
}
parse_post_frontmatter :: (frontmatter: string) -> Post {
	post: Post;
	doc := frontmatter;
	while doc.count > 0 {
		key := doc;
		while !starts_with(doc, ": ") advance(*doc);
		key.count -= doc.count;
		advance(*doc, 2);

		value := doc;
		advance_to_newline(*doc);
		value.count -= doc.count;

		// There's probably a magic-metaprogram-thing to do to write into the posts, but i'd rather do the easy thing for now
		if key == {
			case "title";
				post.title = value;
			case "slug";
				post.slug = value;
			case "pubDatetime";
				ct: Calendar_Time;
				splitted := split(value, "-");
				post.pub_date_time.year = to_integer(splitted[0]).(s32);
				post.pub_date_time.month_starting_at_0 = (to_integer(splitted[1]) - 1).(s8);
				post.pub_date_time.day_of_month_starting_at_0 = (to_integer(splitted[2]) - 1).(s8);
			case "tags";
				post.tags = split(value, ", ");
			case "description";
				post.description = value;
			case;
				log_error("Unknown key in post frontmatter (key: %, value: %)", key, value);
		}

		skip_line(*doc);
	}

	return post;
}

parse_project_frontmatter :: (frontmatter: string) -> Project {
	project: Project;
	doc := frontmatter;
	while doc.count > 0 {
		key := doc;
		while !starts_with(doc, ": ") advance(*doc);
		key.count -= doc.count;
		advance(*doc, 2);

		value := doc;
		advance_to_newline(*doc);
		value.count -= doc.count;

		// There's probably a magic-metaprogram-thing to do to write into the projects, but i'd rather do the easy thing for now
		if key == {
			case "title";
				project.title = value;
			case "slug";
				project.slug = value;
			case "pubDatetime";
				ct: Calendar_Time;
				splitted := split(value, "-");
				project.pub_date_time.year = to_integer(splitted[0]).(s32);
				project.pub_date_time.month_starting_at_0 = (to_integer(splitted[1]) - 1).(s8);
				project.pub_date_time.day_of_month_starting_at_0 = (to_integer(splitted[2]) - 1).(s8);
			case "description";
				project.description = value;
			case "heroImage";
				project.hero_image = value;
			case "teamSize";
				project.team_size = to_integer(value);
			case "toolsUsed";
				project.tools_used = value;
			case "timeFrame";
				project.time_frame = value;
			case;
				log_error("Unknown key in project frontmatter (key: %, value: %)", key, value);
		}

		skip_line(*doc);
	}

	return project;
}

render_jaitml :: (path: string) -> string, bool {
	content, ok := read_entire_file(path);
	if !ok return "", false;

	code := false;
	sb: String_Builder;
	result: String_Builder;

	i := 0;
	while i < content.count - 1 {
		s := slice(content, i, content.count - 1);
		if !code {
			if starts_with(s, OPEN_TAG) {
				str := builder_to_string(*sb);
				if str != "" then print_to_builder(*result, "echo(\"%\");\n", str);
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
		if !code then print_to_builder(*result, "echo(\"%\");\n", str);
		else print_to_builder(*result, "%\n", str);
	}

	return builder_to_string(*result), true;
}

execute_jaitml :: ($path: string, output_path: string, $extra_code: Code = #code {}) #expand {
	jaitml_string_builder: String_Builder;
	echo :: (format_string: string, args: ..Any) #expand {
		print_to_builder(*jaitml_string_builder, format_string, ..args);
	}
	include :: ($include_path: string) #expand {
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

	#insert -> string {
		sb: String_Builder;
		for posts {
			print_to_builder(*sb, "title = \"% - Fabian Huber\";", it.title);
			print_to_builder(*sb, "execute_jaitml(\"src/post.html.jaitml\", tprint(\"\%posts/%/index.html\", BUILD_DIR), #code { POST_INDEX :: %; });", it.slug, it_index);
		}
		return builder_to_string(*sb);
	};

	#insert -> string {
		sb: String_Builder;
		for projects {
			print_to_builder(*sb, "title = \"% - Fabian Huber\";", it.title);
			print_to_builder(*sb, "execute_jaitml(\"src/project.html.jaitml\", tprint(\"\%projects/%/index.html\", BUILD_DIR), #code { PROJECT_INDEX :: %; });", it.slug, it_index);
		}
		return builder_to_string(*sb);
	};

	title = "Fabian Huber";
	execute_jaitml("src/index.html.jaitml", tprint("%index.html", BUILD_DIR));
	title = "Posts - Fabian Huber";
	execute_jaitml("src/posts.html.jaitml", tprint("%/posts/index.html", BUILD_DIR));
	title = "Projects - Fabian Huber";
	execute_jaitml("src/projects.html.jaitml", tprint("%/projects/index.html", BUILD_DIR));
}
