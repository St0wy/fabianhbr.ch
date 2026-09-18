---
title: Making my own custom site generator using Jai metaprogramming magic
slug: custom-site-generator-jai
pub_date_time: 2026-07-25
tags: web, static-site-generator, jai
description: Why use Jekyll, Hugo, Astro, or Node when you can reinvent the wheel and write a custom templating engine and Markdown parser in Jai?
bluesky_url: https://bsky.app/profile/stowy.ch/post/3mrhpptquis2e
---

I created my previous portfolio website using [Astro](https://astro.build/), but when it came time to add new stuff to it, 
npm refused to run the build command because after downloading 623 dependencies, it found security risks in some of the packages.
The next problem was that the project was using Astro 4. It started on Astro 3 and I upgraded it to v4 painfully.
But now the most recent version is v7.1!

After all this frustration, being inspired by [gingerBill's video](https://www.youtube.com/watch?v=YvnTsiIFXeI),
I decided to reinvent the wheel and make my own [static site generator (SSG)](https://en.wikipedia.org/wiki/Static_site_generator).
Except that instead of having my code copy and paste the header/footer by hand, I thought it would be fun to try to make a templating system using
[Jai](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/01A_What_is_Jai.md)'s powerful metaprogramming features.
The approach I chose was inspired by the work presented in [Tsoding's livestream](https://www.youtube.com/watch?v=OpoxlJ9e3Qg) where he does exactly that.
I then pushed the concept further and also added a handmade Markdown parser.

In this post, I will present how I made this Jai templating system, and then present my Markdown parser.

## The Jai templating system

So what do I mean by that? Well, I wanted something where I could reuse some HTML and put some logic inside of it to, for example, display a list of blog posts.
My goal was to make something that would specifically work for my needs, and not something hyper robust and generalized.
I decided to call it _Jaitml_ and it looks like this:

```html
// index.jaitml
<?jai include("header.jaitml"); ?>
<main>
	<p>Hi! My name is Fabian Huber. I am a Game & Graphics Programmer.</p>
	<ul>
		<?jai for post: posts { ?>
		<li><?jai echo("%", post.title); ?></li>
		<?jai } ?>
	</ul>
</main>
<?jai include("footer.jaitml"); ?>
```

As you can see, it allows me to write some Jai code inside of HTML to copy the content of other files and basically write any logic I might want when I generate my website.
This is done in a `generator.jai` file that handles this. Since it relies on the compiler to run this code, I decided to do everything at compile-time.
Something that is easy to do in Jai, using the `#run` directive where I call `set_build_options_dc({do_output = false});` to tell the compiler to not create an executable.

I then have a `render_jaitml :: (path: string) -> string` procedure that takes my `.jaitml` file and converts it to Jai code. A simple file like this:

```html
<?jai include("header.jaitml"); ?>
<main>
	<p>Hi.</p>
</main>
<?jai include("footer.jaitml"); ?>
```

Would be converted to :

```jai
include("header.jaitml");
append(*jaitml_string_builder, "<main>\n<p>Hi.</p>\n</main>\n");
include("footer.jaitml");
```

The HTML is appended directly to the string builder instead of going through `echo`.
Since `echo` takes a format string, any `%` in my HTML would otherwise be interpreted as a format specifier.

Then to execute this code, I need to get the code string as a constant, meaning that it has to go through another `#run` directive (so this is at compile-compile-time).
It can then be `#insert`-ed.

```jai
code :: #run render_jaitml(path);
#insert,scope() code;
```

The templating system mostly works with two macros: `include` and `echo`. These are declared just above the call to `render_jaitml` like so:

```jai
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
```

At the end, `jaitml_string_builder` contains the final HTML code and is written to an output file.
Now, to read the posts, I simply declared a global constant `posts` variable that is filled up in a `#run` block (more on this later).

To generate one page per post, it was a bit more tricky.
First, when generating the page, I needed to know which post to generate it for.
This required me to add a `$extra_code: Code` block parameter to my macro where I could pass the post index like that:

```jai
execute_jaitml("src/post.html.jaitml", tprint("%posts/slug/index.html", BUILD_DIR), #code { POST_INDEX :: index; });
```

However, to make this work, I had to put the code that calls `render_jaitml` in a `#code` block too,
merge them into one, and insert that because it is not possible to access the variables from one block in another.
My final `execute_jaitml` procedure looks like this:

```jai
execute_jaitml :: (
	$path: string, 
	output_path: string, 
	$extra_code: Code = #code {}
) #expand {
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
```

One other problem is that any file included through `include` is also not able to read this information.
This was a problem when setting the title of the page since it had to be set in the header.
To fix that, I declared a few global variables for the page metadata (the title, the description and the Open Graph data used for link previews),
that a `set_page_meta` procedure fills before calling `execute_jaitml`.
This means I could also do that for the post indices, and get rid of the complication with the `$extra_code`,
but I am not sure of an ideal solution for now, as I'd like to limit global data as much as possible.

Then, another problem appeared when it was time to iterate over the `posts` array and generate the pages.
This is because `execute_jaitml` needs to be executed with the `#run`, so all the parameters must be constants.
The problem is that when you iterate over a constant array, the iterator is not itself constant.

To go around that, I used some more metaprogramming magic and generated the code that would result from an unrolled loop:

```jai
#insert -> string {
	sb: String_Builder;
	for posts {
		print_to_builder(*sb, "set_page_meta(posts[%1].title, tprint(\"/posts/\%/\", posts[%1].slug), posts[%1].description, \"article\");", it_index);
		print_to_builder(*sb, "execute_jaitml(\"src/post.html.jaitml\", tprint(\"\%posts/%/index.html\", BUILD_DIR), #code { POST_INDEX :: %; });", it.slug, it_index);
	}
	return builder_to_string(*sb);
};
```

Note that the generated code reads the title from the `posts` array instead of pasting it inside a string literal.
My first version did the latter, which meant that a `"` in a post title would have broken the compilation.

And with that, the template system is complete!

## Markdown parsing

Now to parse Markdown, I needed a way to first get an abstract syntax tree (AST) that would then be used to generate an HTML output.
Each node stores pointers to other nodes to be able to make the tree and some data that is stored in a [discriminated union](https://en.wikipedia.org/wiki/Tagged_union).
There are two kinds of node types, block types (headings, paragraphs, etc.) and inline types (text, strong, etc.).

```jai
Node_Kind :: enum u8 {
	Document;
	// Blocks
	Heading;
	Paragraph;
	// Inline
	Text;
	Strong;
	// ...
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
```

There isn't a lot in `Node_Data` because more is not needed. Just `level` is used for headings, then content for everything else.
For example, images have an Image node that stores the url in content, then a child Text node that stores the alt.
For the document kind, content stores the frontmatter, and it's the responsibility of the code using the library to parse this.

Since this program only runs shortly and terminates, I never manually free any memory and let the OS take care of that.
However, I still want allocations to be fast.
Since I will be allocating a lot of small nodes, I decided to use the [arena allocator](https://www.dgtlgrove.com/p/untangling-lifetimes-the-arena-allocator) provided by Jai called `Flat_Pool`.
It works by using the virtual address space of the machine.
It reserves a big chunk of memory (256MB by default) in the address space that gets committed each time the currently committed memory runs out.
The node allocation code looks like this:

```jai
#import "Flat_Pool";
pool: Flat_Pool;
a: Allocator;
// a is set in another procedure
// a.proc = flat_pool_allocator_proc;
// a.data = *pool;

make_node :: (kind: Node_Kind, parent: *Ast_Node = null) -> *Ast_Node {
	node := New(Ast_Node,, a);
	node.kind = kind;
	if parent then add_child(parent, node);
	return node;
}
```

The parsing is done in two phases:

1. **Block parsing**: Iterates over the Markdown document to extract the block nodes.
2. **Inline parsing**: Iterates over text nodes and breaks them up to add things like images, bold text, etc.

Parsing is done using an ad-hoc line parser, so the code is not the prettiest,
but most importantly it is not [CommonMark](https://commonmark.org/) compliant.
My goal was to only implement the strict minimum to make my current Markdown documents work.
The only thing I had to change was the frontmatter and tables, which I transformed into HTML ones.
If I ever need more in the future, I can still add it later.

To emit HTML, I iterate over the tree in a depth-first manner using a stackless tree traversal and print the tags in a `String_Builder`.

```jai
emit_html :: (root: *Ast_Node) -> string {
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
```

I also simplified the frontmatter of my documents to make it easier to parse than YAML.
Each line has one key-value pair that is separated by `: `, and each key is the name of the struct member it will be stored in:

```yaml
---
title: 2D C++ Physics Engine
slug: physics-engine
pub_date_time: 2022-07-15
team_size: 1
---
```

This means that I can parse the frontmatter of both my posts and my projects with a single procedure.
Using the type info of the struct, it finds the member with the same name as the key, and writes the value at the offset of this member depending on its type:

```jai
Post :: struct {
	title: string;
	slug: string;
	pub_date_time: Calendar_Time;
	tags: [] string;
	description: string;
	bluesky_url: string;
	html: string; @NoFrontmatter
}

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
				// Parses the YYYY-MM-DD date into the Calendar_Time
				// ...
		}
	}

	return result;
}
```

The `html` member is filled with the output of the Markdown parser, so I marked it with a `@NoFrontmatter` note.
Notes are attached to the type info of the members, which makes it easy to check that a document cannot overwrite it:

```jai
find_frontmatter_member :: (info: *Type_Info_Struct, key: string) -> *Type_Info_Struct_Member {
	for * member: info.members {
		if member.name != key continue;
		for member.notes if it == "NoFrontmatter" return null;
		return member;
	}
	return null;
}
```

Adding a new field to the frontmatter is now just a matter of adding a member to the struct.

Finally, I can create the posts array by getting every file in a folder, parsing them, and then sorting the array to have them chronologically ordered.
Since posts and projects are handled the same way, this is also a single polymorphic procedure:

```jai
posts :: #run load_entries(Post, "posts");
projects :: #run load_entries(Project, "projects");

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
```

## Conclusion

If you are reading this, it means that it worked!
Now since everything runs at compile time, meaning that it is "interpreted", you might wonder how performant it is.
Well, on my AMD Ryzen 9 7900X3D, the entire execution of the program (measured using [Nushell's timeit](https://www.nushell.sh/commands/docs/timeit.html)) is ~700ms.
Most of the time is spent parsing the Markdown, which I'm sure would be wayyy faster if compiled and optimized,
but I think this is good enough for me and being able to write my HTML templates using Jai is fun enough to accept this tradeoff.
I hope I can find a satisfying solution for the global state / per page state problem, but for now the current solution works.

**Update (September 2026):** This post was updated to reflect some changes in the generator. The frontmatter is now parsed using the type info of the structs instead of one hand-written parser per struct, and the page title is now set by `set_page_meta`, which also handles the description and the Open Graph tags.

If you're curious, you can read the code of this website on [GitHub](https://github.com/St0wy/fabianhbr.ch).
