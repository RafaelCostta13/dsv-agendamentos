const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");

for (const code of [401, 403]) {
  test(`HTTP ${code} hides administrative data, stops polling and redirects`, async () => {
    const timers = new Map();
    let sequence = 0;
    let redirected;
    const shell = { hidden: false };
    const listener = { addEventListener() {}, removeEventListener() {} };
    const input = { ...listener, value: "2026-11-25" };
    const form = { ...listener, elements: { date: input }, reportValidity() { return true; } };
    const status = { parentElement: { dataset: { state: "active" } } };
    const root = { ...listener, dataset: { interval: "5000", timeout: "10000", maxRetry: "30000", refreshUrl: "/admin/dashboard/refresh" },
      querySelector(selector) { return { "#dashboard-date-form": form, "[data-polling-status]": status, "[data-polling-time]": {} }[selector]; } };
    const document = { ...listener, hidden: false, readyState: "complete", querySelector(selector) { return selector === "#dashboard-polling" ? root : shell; } };
    const window = { ...listener };
    const location = { href: "http://localhost/admin", assign(url) { redirected = url; } };
    const context = { window, document, location, URL, AbortController, Symbol,
      setTimeout(fn) { const id = ++sequence; timers.set(id, fn); return id; }, clearTimeout(id) { timers.delete(id); },
      fetch: async () => ({ status: code, headers: { get() { return "/login"; } } }) };
    vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../../app/assets/javascripts/dashboard_polling.js"), "utf8"), context);
    const [id, callback] = [...timers][0];
    timers.delete(id);
    await callback();
    assert.equal(shell.hidden, true);
    assert.equal(redirected, "/login");
    assert.equal(timers.size, 0);
  });
}
