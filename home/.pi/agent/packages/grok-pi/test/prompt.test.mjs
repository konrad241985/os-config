import assert from "node:assert/strict";
import test from "node:test";
import { buildPrompt } from "../src/cli.ts";

test("system messages with string content do not crash and keep the prompt and tools", () => {
	const prompt = buildPrompt({
		messages: [
			{
				role: "system",
				content: "You are Pi",
				toolsAdded: [
					{ name: "read", description: "Read a file", parameters: { type: "object" } },
					{ name: "bash", description: "Run a command", parameters: { type: "object" } },
				],
				timestamp: 0,
			},
			{
				role: "system",
				content: "",
				toolsRemoved: [{ name: "bash" }],
				timestamp: 1,
			},
			{ role: "user", content: "hello", timestamp: 2 },
		],
	});

	assert.match(prompt, /# Pi system prompt\n\nYou are Pi/);
	assert.match(prompt, /"name": "read"/);
	assert.doesNotMatch(prompt, /"name": "bash"/);
	assert.match(prompt, /USER:\nhello/);
	assert.doesNotMatch(prompt, /SYSTEM:/);
});

test("assistant text and tool calls still serialize", () => {
	const prompt = buildPrompt({
		systemPrompt: "stay brief",
		tools: [{ name: "read", description: "Read a file", parameters: { type: "object" } }],
		messages: [
			{
				role: "assistant",
				content: [
					{ type: "text", text: "looking" },
					{ type: "toolCall", name: "read", arguments: { path: "a.txt" } },
				],
				timestamp: 1,
			},
		],
	});

	assert.match(prompt, /ASSISTANT:\nlooking\n<pi_tool_call>/);
	assert.match(prompt, /"name": "read"/);
	assert.match(prompt, /"path": "a\.txt"/);
	assert.match(prompt, /# Pi system prompt\n\nstay brief/);
});
