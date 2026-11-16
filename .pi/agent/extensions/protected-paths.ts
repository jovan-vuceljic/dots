/**
 * Protected Paths Extension
 *
 * Blocks write and edit operations to protected paths.
 *
 * Adapted from pi's bundled `examples/extensions/protected-paths.ts`. Upstream ships a
 * three-entry demo list (.env, .git/, node_modules/); the list below names the files
 * that actually matter in this dotfiles tree — the ones holding secrets, and the git
 * metadata the agent has no business rewriting.
 *
 * Scope, so this isn't over-trusted: it guards against the *model* calling write/edit.
 * It cannot stop pi's own `/login`, which rewrites auth.json with the literal key —
 * that is why auth.json is gitignored and auth.json.example is the tracked copy.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const protectedPaths = [
		// Secrets. `secrets.fish` holds $DUSKADIY_API_KEY; auth.json is pi's own
		// credential map and must keep $VAR references rather than literals.
		"secrets.fish",
		"auth.json",
		".env",
		"fish_variables",

		// Credentials outside the repo.
		".ssh/",
		".gnupg/",
		".aws/",
		".netrc",

		// Repo plumbing and vendored trees — never hand-edited.
		".git/",
		"node_modules/",
	];

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "write" && event.toolName !== "edit") {
			return undefined;
		}

		const path = event.input.path as string;
		// Substring match, like upstream: cheap, and these names are distinctive enough.
		// Note `auth.json.example` is intentionally caught too — it is a tracked file
		// whose whole job is to contain no secret, so an agent rewrite is worth a look.
		const isProtected = protectedPaths.some((p) => path.includes(p));

		if (isProtected) {
			if (ctx.hasUI) {
				ctx.ui.notify(`Blocked write to protected path: ${path}`, "warning");
			}
			return { block: true, reason: `Path "${path}" is protected` };
		}

		return undefined;
	});
}
