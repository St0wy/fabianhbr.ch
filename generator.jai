#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
#import "Program_Print";

Markdown :: #import "Markdown";

OPEN_TAG :: "<?jai";
CLOSE_TAG :: "?>";
BUILD_DIR :: "public/";
TEMPLATE_EXTENSION :: ".jaitml";

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

execute_jaitml :: ($path: string, output_dir: string, $extra_code: Code = #code {}) #expand {
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

			current_file_path := parse_path(path);
			filename := current_file_path.words[current_file_path.words.count - 1];
			if ends_with(filename, TEMPLATE_EXTENSION) filename.count -= TEMPLATE_EXTENSION.count;
			final_path := tprint("%%", output_dir, filename);
			write_entire_file(final_path, *jaitml_string_builder);
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

	start := current_time_monotonic();

	ok := make_directory_if_it_does_not_exist(BUILD_DIR);
	assert(ok);

	execute_jaitml("src/index.html.jaitml", BUILD_DIR, #code {
		Post :: struct {
			title: string;
			description: string;
			url: string;
		}
		posts: [..] Post;

		visit_files("src/posts", false, *posts, (info: *File_Visit_Info, data: *[..] Post) {
			if info.is_directory then return;
			ext, ok := path_extension(info.short_name);
			if !ok then return;
			if ext != ".md" then return;
			array_add(data, {copy_string(info.short_name), "", ""});
		});
	});
	test_post := read_entire_file("src/posts/test.md");
	node := Markdown.parse_blocks(test_post);
	// execute_jaitml("src/rss.xml.jaitml", BUILD_DIR);

	end := current_time_monotonic();
	print("Generated site in %ms\n", to_float64_seconds(end - start) * 1000);
}
