// Highlights the code blocks of the website at build time, so the pages are served already highlighted.
// It is run by generator.jai with Bun, and uses the highlight.js scripts copied in vendor/.
//
// Usage: bun tools/highlight/highlight.js <input file> <output file>
// Input:  for each block "<language>\n<code byte count>\n<code>"
// Output: for each block, in the same order, "<html byte count>\n<html>"

import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const SCRIPTS = [
	"highlight.min.js", // Must be first, the grammars register themselves on the global hljs
	"cmake.min.js",
	"dos.min.js",
	"glsl.min.js",
	"jai.min.js",
	"nushell.min.js",
	"powershell.min.js",
	"zig.min.js",
	"typst.bundle.js", // From @myriaddreamin/highlighter-typst, it uses the parser of Typst compiled to WASM
];

globalThis.window = globalThis; // Some grammars expect to run in a browser
for (const script of SCRIPTS) {
	// Indirect eval runs the script in the global scope, like a <script> tag would
	(0, eval)(readFileSync(join(import.meta.dir, "vendor", script), "utf8"));
}
const hljs = globalThis.hljs;

// The Typst grammar can only be registered once its WASM module is loaded
await globalThis.$typst$parserModule;
hljs.registerLanguage("typst", globalThis.hljsTypst());

const [inputPath, outputPath] = process.argv.slice(2);
const blocks = readBlocks(readFileSync(inputPath));
trimJaiGrammar(blocks);

const output = [];
for (const { language, code } of blocks) {
	const html = language && hljs.getLanguage(language)
		? hljs.highlight(code, { language, ignoreIllegals: true }).value
		: escapeHtml(code);
	output.push(`${Buffer.byteLength(html)}\n`, html);
}
writeFileSync(outputPath, output.join(""));

function readBlocks(input) {
	const blocks = [];
	let position = 0;
	const readLine = () => {
		const end = input.indexOf(0x0a, position);
		const line = input.toString("utf8", position, end);
		position = end + 1;
		return line;
	};

	while (position < input.length) {
		const language = readLine();
		const byteCount = Number(readLine());
		const code = input.toString("utf8", position, position + byteCount);
		position += byteCount;
		blocks.push({ language, code });
	}
	return blocks;
}

// The Jai grammar lists ~40000 standard library names, and compiling all of them takes seconds.
// Only keep the ones that appear in the code being highlighted, which gives the same result.
function trimJaiGrammar(blocks) {
	const jai = hljs.getLanguage("jai");
	if (!jai) return;

	const usedWords = new Set();
	for (const { language, code } of blocks) {
		if (language !== "jai") continue;
		for (const word of code.match(/[A-Za-z_][A-Za-z0-9_]*/g) || []) usedWords.add(word);
	}

	const rawDefinition = jai.rawDefinition;
	hljs.registerLanguage("jai", (hljs) => {
		const definition = rawDefinition(hljs);
		const visited = new Set();
		(function trim(mode) {
			if (!mode || typeof mode !== "object" || visited.has(mode)) return;
			visited.add(mode);
			if (mode.keywords && typeof mode.keywords === "object") {
				for (const [scope, words] of Object.entries(mode.keywords)) {
					if (!scope.includes("stdLib")) continue;
					const list = Array.isArray(words) ? words : String(words).split(/\s+/);
					mode.keywords[scope] = list.filter((word) => usedWords.has(word));
				}
			}
			Object.values(mode).forEach(trim);
		})(definition);
		return definition;
	});
}

function escapeHtml(text) {
	return text
		.replaceAll("&", "&amp;")
		.replaceAll("<", "&lt;")
		.replaceAll(">", "&gt;")
		.replaceAll('"', "&quot;")
		.replaceAll("'", "&#x27;");
}
