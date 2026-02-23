module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    "max-len": ["warn", {code: 200}], // ⬅️ Increase line length to 200
    "object-curly-spacing": ["error", "never"], // ⬅️ Enforce no spacing
    "comma-dangle": ["error", "always-multiline"], // ⬅️ Trailing commas
    "indent": ["error", 2], // ⬅️ Explicitly enforce 2-space indent
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
