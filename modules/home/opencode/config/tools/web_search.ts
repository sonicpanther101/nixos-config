import { tool } from "@opencode-ai/plugin"

// Local SearXNG (services.searx in this VM). No API key, no third party sees the query
// beyond the engines SearXNG itself queries.
export default tool({
  description:
    "Search the web and return titles, URLs and snippets. Use webfetch afterwards on the best results to read them.",
  args: {
    query: tool.schema.string().describe("Search query"),
    max_results: tool.schema.number().optional().describe("Maximum results (default 8)"),
  },
  async execute(args) {
    const url = new URL("http://127.0.0.1:8888/search")
    url.searchParams.set("q", args.query)
    url.searchParams.set("format", "json")
    const res = await fetch(url, { signal: AbortSignal.timeout(20000) })
    if (!res.ok) return `Search failed: HTTP ${res.status}`
    const data: any = await res.json()
    const n = args.max_results ?? 8
    const rows = (data.results ?? []).slice(0, n).map(
      (r: any, i: number) => `${i + 1}. ${r.title}\n   ${r.url}\n   ${(r.content ?? "").replace(/\s+/g, " ").trim()}`,
    )
    return rows.length ? rows.join("\n\n") : "No results."
  },
})
