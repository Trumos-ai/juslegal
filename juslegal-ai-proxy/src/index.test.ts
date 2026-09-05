import { describe, expect, it } from "vitest";
import { parseRequestJson, sanitizeUpstreamPayload } from "./index";

describe("AI request validation", () => {
	it("parses a normal HTTP JSON body instead of treating it as a JWT segment", () => {
		const raw = parseRequestJson(
			'{"messages":[{"role":"user","content":"Need help"}],"max_tokens":1200}',
		);
		const result = sanitizeUpstreamPayload(raw, "openrouter/auto");

		expect(result.reason).toBeNull();
		expect(result.payload).toMatchObject({
			model: "openrouter/auto",
			max_tokens: 1200,
		});
	});

	it("ignores a browser-supplied model and uses the endpoint allow-list", () => {
		const result = sanitizeUpstreamPayload(
			{ model: "untrusted/model", messages: [{ role: "user", content: "Hello" }] },
			"openai/gpt-oss-20b",
		);

		expect(result.reason).toBeNull();
		expect(result.payload?.model).toBe("openai/gpt-oss-20b");
	});

	it("returns a safe reason for malformed request JSON", () => {
		const result = sanitizeUpstreamPayload(parseRequestJson("not json"), "openrouter/auto");

		expect(result).toEqual({ payload: null, reason: "invalid_json_object" });
	});
});
