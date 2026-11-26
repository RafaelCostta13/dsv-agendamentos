(() => {
  // Re-executing the asset (for example after Turbo navigation) replaces its lifecycle.
  const lifecycleKey = Symbol.for("dsv.dashboardPolling");
  window[lifecycleKey]?.destroy();

  class DashboardPolling {
    constructor(root) {
      this.root = root;
      this.form = root.querySelector("#dashboard-date-form");
      this.input = this.form.elements.date;
      this.status = root.querySelector("[data-polling-status]");
      this.statusBox = this.status.parentElement;
      this.time = root.querySelector("[data-polling-time]");
      this.interval = Number(root.dataset.interval);
      this.timeout = Number(root.dataset.timeout);
      this.maxRetry = Number(root.dataset.maxRetry);
      this.date = this.input.value;
      this.failures = 0;
      this.generation = 0;
      this.connected = true;
      this.expired = false;
      this.onSubmit = (event) => { event.preventDefault(); this.refresh(); };
      this.onDate = () => this.refresh();
      this.onVisibility = () => {
        if (document.hidden) {
          this.cancel();
          this.pointerActive = false;
          clearTimeout(this.interactionTimer);
          this.show("paused");
        } else this.refresh();
      };
      this.onPointerDown = () => { this.pointerActive = true; };
      this.onPointerEnd = () => {
        clearTimeout(this.interactionTimer);
        this.interactionTimer = setTimeout(() => {
          this.pointerActive = false;
          if (this.pending && this.connected && !document.hidden) this.apply(this.pending);
          this.pending = null;
        }, 0);
      };
      this.form.addEventListener("submit", this.onSubmit);
      this.input.addEventListener("change", this.onDate);
      this.root.addEventListener("pointerdown", this.onPointerDown);
      window.addEventListener("pointerup", this.onPointerEnd);
      window.addEventListener("pointercancel", this.onPointerEnd);
      document.addEventListener("visibilitychange", this.onVisibility);
      if (document.hidden) this.show("paused");
      else if (this.statusBox.dataset.state === "paused") this.refresh();
      else this.schedule(this.interval);
    }

    show(state) {
      const labels = {
        active: "Atualização automática ativa",
        updating: "Atualizando...",
        failed: "Falha na atualização. Exibindo os últimos dados recebidos.",
        paused: "Atualização automática pausada"
      };
      this.statusBox.dataset.state = this.failures && state !== "paused" ? "failed" : state;
      // A failed snapshot remains marked until a successful replacement.
      this.status.textContent = this.failures && state !== "paused" ? labels.failed : labels[state];
    }

    schedule(delay) {
      clearTimeout(this.timer);
      if (this.connected && !document.hidden) this.timer = setTimeout(() => this.refresh(), delay);
    }

    cancel() {
      clearTimeout(this.timer);
      clearTimeout(this.requestTimer);
      this.generation += 1;
      this.request?.abort();
      this.request = null;
      this.pending = null;
    }

    async refresh() {
      if (!this.connected || document.hidden || !this.form.reportValidity()) return;
      const date = this.input.value;
      if (this.request && date === this.date) return;
      this.cancel();
      this.date = date;
      const generation = this.generation;
      const controller = new AbortController();
      this.request = controller;
      this.show("updating");
      const url = new URL(this.root.dataset.refreshUrl, location.href);
      url.searchParams.set("date", date);
      try {
        const deadline = new Promise((_, reject) => {
          this.requestTimer = setTimeout(() => {
            controller.abort();
            reject(new Error("timeout"));
          }, this.timeout);
        });
        const load = async () => {
          const response = await fetch(url, { signal: controller.signal, credentials: "same-origin", cache: "no-store", headers: { Accept: "text/html" } });
          if (response.status === 401 || response.status === 403) {
            this.expired = true;
            this.connected = false;
            this.cancel();
            const content = document.querySelector(".admin-shell");
            if (content) content.hidden = true;
            location.assign(response.headers.get("X-Login-URL") || "/login?expired=1");
            throw new Error("expired");
          }
          if (!response.ok || response.redirected || !response.headers.get("Content-Type")?.includes("text/html")) throw new Error("response");
          return response.text();
        };
        const html = await Promise.race([load(), deadline]);
        if (!this.current(generation, date)) return;
        const parsed = new DOMParser().parseFromString(html, "text/html");
        const nodes = parsed.querySelectorAll("#dashboard-data");
        const node = nodes[0];
        if (nodes.length !== 1 || node.dataset.date !== date ||
            !/^\d{4}-\d{2}-\d{2}T/.test(node.dataset.updatedAt || "") ||
            !/^\d{2}:\d{2}:\d{2}$/.test(node.dataset.updatedLabel || "") ||
            node.querySelectorAll(".admin-indicator").length !== 5 ||
            node.querySelectorAll(".admin-matrix tbody tr").length !== 8 ||
            node.querySelectorAll(".admin-matrix tbody td").length !== 80 ||
            node.querySelectorAll(".admin-matrix thead th").length !== 11 ||
            node.querySelector("script, iframe, object, embed")) throw new Error("incomplete");
        const snapshot = { node, date, generation };
        if (this.pointerActive) this.pending = snapshot;
        else this.apply(snapshot);
      } catch (_) {
        if (this.expired) return;
        if (!this.current(generation, date)) return;
        this.failures += 1;
        this.show("failed");
      } finally {
        if (this.current(generation, date)) {
          clearTimeout(this.requestTimer);
          this.request = null;
          this.schedule(this.failures ? Math.min(this.interval * 2 ** Math.min(this.failures - 1, 3), this.maxRetry) : this.interval);
        }
      }
    }

    current(generation, date) {
      return this.connected && !document.hidden && generation === this.generation && date === this.input.value;
    }

    apply({ node, date, generation }) {
      if (!this.current(generation, date)) return;
      const previous = this.root.querySelector("#dashboard-data");
      const scroller = previous.querySelector(".admin-table-scroll");
      const horizontal = scroller?.scrollLeft || 0;
      const vertical = scroller?.scrollTop || 0;
      const x = window.scrollX, y = window.scrollY;
      const active = document.activeElement;
      const focused = previous.contains(active);
      const href = focused && active.closest("a[href]")?.getAttribute("href");
      previous.replaceWith(node);
      const replacement = node.querySelector(".admin-table-scroll");
      if (replacement) {
        replacement.scrollLeft = horizontal;
        replacement.scrollTop = vertical;
      }
      if (focused) {
        const target = href && [...node.querySelectorAll("a[href]")].find((link) => link.getAttribute("href") === href);
        (target || replacement)?.focus({ preventScroll: true });
      }
      window.scrollTo(x, y);
      this.time.dateTime = node.dataset.updatedAt;
      this.time.textContent = node.dataset.updatedLabel;
      const link = document.querySelector("[data-dashboard-bookings]");
      if (link) {
        const target = new URL(link.href);
        target.searchParams.set("date", date);
        link.href = target.href;
      }
      const currentUrl = new URL(location.href);
      currentUrl.searchParams.set("date", date);
      history.replaceState(history.state, "", currentUrl);
      this.failures = 0;
      this.show("active");
    }

    disconnect() {
      this.connected = false;
      this.cancel();
      clearTimeout(this.interactionTimer);
      this.form.removeEventListener("submit", this.onSubmit);
      this.input.removeEventListener("change", this.onDate);
      this.root.removeEventListener("pointerdown", this.onPointerDown);
      window.removeEventListener("pointerup", this.onPointerEnd);
      window.removeEventListener("pointercancel", this.onPointerEnd);
      document.removeEventListener("visibilitychange", this.onVisibility);
      this.show("paused");
    }
  }

  let current;
  const boot = (event) => {
    const root = document.querySelector("#dashboard-polling");
    if (current?.root === root && current.connected) return;
    current?.disconnect();
    current = root ? new DashboardPolling(root) : null;
    if (event?.type === "pageshow" && event.persisted) current?.refresh();
  };
  const stop = () => { current?.disconnect(); current = null; };
  const events = [[document, "DOMContentLoaded", boot], [document, "turbo:load", boot], [document, "turbo:before-cache", stop], [window, "pagehide", stop], [window, "pageshow", boot]];
  events.forEach(([target, name, callback]) => target.addEventListener(name, callback));
  window[lifecycleKey] = { destroy() { stop(); events.forEach(([target, name, callback]) => target.removeEventListener(name, callback)); } };
  if (document.readyState !== "loading") boot();
})();
