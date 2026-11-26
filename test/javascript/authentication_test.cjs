const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");

test("eye button reveals and conceals the password while preserving its icon", () => {
  const input = { type: "password", value: "Senha de teste" };
  const attributes = {};
  let click;
  const icon = {};
  const button = {
    icon,
    addEventListener(event, handler) { assert.equal(event, "click"); click = handler; },
    closest() { return { querySelector() { return input; } }; },
    setAttribute(name, value) { attributes[name] = value; }
  };
  const document = { querySelectorAll() { return [button]; } };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../../app/assets/javascripts/authentication.js"), "utf8"), { document });
  click();
  assert.equal(input.type, "text");
  assert.equal(attributes["aria-label"], "Ocultar senha");
  assert.equal(attributes["aria-pressed"], "true");
  assert.equal(button.icon, icon);
  click();
  assert.equal(input.type, "password");
  assert.equal(attributes["aria-label"], "Mostrar senha");
  assert.equal(attributes["aria-pressed"], "false");
  assert.equal(input.value, "Senha de teste");
});
