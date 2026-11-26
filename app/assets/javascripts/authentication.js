(() => {
  document.querySelectorAll("[data-password-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      const input = button.closest(".auth-password")?.querySelector("[data-password-input]");
      if (!input) return;
      const visible = input.type === "text";
      input.type = visible ? "password" : "text";
      const label = visible ? "Mostrar senha" : "Ocultar senha";
      button.setAttribute("aria-label", label);
      button.title = label;
      button.setAttribute("aria-pressed", String(!visible));
    });
  });
})();
