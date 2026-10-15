import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  copyFileSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readlinkSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { updateClientVersions } from "./client-versions.mjs";

const repo = fileURLToPath(new URL("../..", import.meta.url));
const pinned =
  "CLIENT_VERSION=5.1.0-rc3\nCLIENT_NAME=JumpServer\nCLIENT_RELEASE_TAG=v5.1.0-rc3\n" +
  "WEBLITE_VERSION=5.1.0-rc3\nWEBLITE_RELEASE_TAG=v5.1.0-rc3\n";

function release(target, version, overrides = {}) {
  const names =
    target === "client"
      ? [`JumpServer-${version}-Setup.exe`, `JumpServer-${version}-arm64.dmg`]
      : [`JumpServer-WebLite-${version}-x64.msi`];
  return {
    tag_name: `${target}-v${version}`,
    draft: false,
    prerelease: false,
    assets: names.map((name) => ({ name, size: 1024 })),
    ...overrides,
  };
}

test("selects complete published releases independently by version, preserving installer names", () => {
  const releases = [
    release("client", "5.1.9"),
    release("weblite", "5.2.0"),
    release("client", "5.1.10"),
    release("client", "6.0.0", { draft: true }),
    release("client", "7.0.0", { prerelease: true }),
    release("client", "8.0.0", { assets: [] }),
    release("client", "9.0.0", { tag_name: "v9.0.0" }),
  ];
  const content = updateClientVersions(pinned, releases);
  assert.match(content, /^CLIENT_VERSION=5\.1\.10$/m);
  assert.match(content, /^CLIENT_RELEASE_TAG=client-v5\.1\.10$/m);
  assert.match(content, /^WEBLITE_VERSION=5\.2\.0$/m);
  assert.match(content, /^WEBLITE_RELEASE_TAG=weblite-v5\.2\.0$/m);
  assert.equal(updateClientVersions(content, releases), content);
  assert.equal(
    releases.reduce((pins, item) => updateClientVersions(pins, [item]), pinned),
    content,
  );
});

test("client-only updates retain the pinned WebLite and its existing legacy release", () => {
  const content = updateClientVersions(pinned, [release("client", "5.1.0")]);
  assert.match(content, /^CLIENT_VERSION=5\.1\.0$/m);
  for (const line of pinned.split("\n").filter((line) => line.startsWith("WEBLITE_"))) {
    assert.ok(content.split("\n").includes(line));
  }
});

test("late, malformed and incomplete releases cannot downgrade either product", () => {
  assert.equal(
    updateClientVersions(pinned, [
      release("client", "5.0.0"),
      release("weblite", "5.0.0"),
      release("client", "5.01.0"),
      release("weblite", "5.1.0-01"),
      release("client", "6.0.0", { assets: [{ name: "JumpServer-6.0.0-Setup.exe", size: 1024 }] }),
      release("weblite", "6.0.0", {
        assets: [{ name: "JumpServer-WebLite-6.0.0-x64.msi", size: 0 }],
      }),
    ]),
    pinned,
  );
  assert.throws(() =>
    updateClientVersions(pinned.replace("CLIENT_VERSION=", "INVALID_VERSION="), []),
  );
  assert.throws(() =>
    updateClientVersions(
      pinned.replace("CLIENT_RELEASE_TAG=v", "CLIENT_RELEASE_TAG=weblite-v"),
      [],
    ),
  );
});

test("orders promoted release candidates numerically", () => {
  const baseline = pinned.replaceAll("5.1.0-rc3", "5.1.0-rc.3");
  assert.match(
    updateClientVersions(baseline, [
      release("weblite", "5.1.0-rc.10"),
      release("weblite", "5.1.0-rc.9"),
    ]),
    /^WEBLITE_VERSION=5\.1\.0-rc\.10$/m,
  );
});

test("the checked-in pins have matching versions and release tags", () => {
  const content = readFileSync(path.join(repo, "client-version.txt"), "utf8");
  assert.equal(updateClientVersions(content, []), content);
});

function download(context, settings) {
  const root = mkdtempSync(path.join(os.tmpdir(), "docker-web-downloads-"));
  context.after(() => rmSync(root, { recursive: true, force: true }));
  copyFileSync(path.join(repo, "client.sh"), path.join(root, "client.sh"));
  writeFileSync(path.join(root, "client-version.txt"), settings);
  mkdirSync(path.join(root, "bin"));
  writeFileSync(
    path.join(root, "bin/wget"),
    `#!/bin/sh
set -eu
printf '%s\\n' "$3" >> "$DOWNLOAD_LOG"
printf '%s\\n' "$3" > "\${2#--output-document=}"
`,
    { mode: 0o755 },
  );
  const log = path.join(root, "downloads");
  const result = spawnSync("sh", [path.join(root, "client.sh")], {
    env: {
      ...process.env,
      PATH: `${path.join(root, "bin")}:${process.env.PATH}`,
      DOWNLOAD_LOG: log,
      CLIENT_DOWNLOAD_DIR: path.join(root, "public"),
      WEBLITE_DOWNLOAD_DIR: path.join(root, "applets"),
      CLIENT_RELEASE_URL: "",
      WEBLITE_RELEASE_URL: "",
      CLIENT_RELEASE_TAG: "",
      WEBLITE_RELEASE_TAG: "",
    },
    encoding: "utf8",
    timeout: 10_000,
  });
  assert.equal(result.status, 0, result.stderr);
  return { root, urls: readFileSync(log, "utf8").trim().split("\n") };
}

test("downloader uses separate release tags while retaining public filenames and aliases", (context) => {
  const { root, urls } = download(
    context,
    "CLIENT_VERSION=5.1.1\nCLIENT_NAME=JumpServer\nWEBLITE_VERSION=5.2.0\n",
  );
  assert.deepEqual(urls, [
    "https://github.com/jumpserver/luna/releases/download/client-v5.1.1/JumpServer-5.1.1-Setup.exe",
    "https://github.com/jumpserver/luna/releases/download/client-v5.1.1/JumpServer-5.1.1-arm64.dmg",
    "https://github.com/jumpserver/luna/releases/download/weblite-v5.2.0/JumpServer-WebLite-5.2.0-x64.msi",
  ]);
  assert.equal(
    readlinkSync(path.join(root, "public/Client_5.1.1_x64-setup.exe")),
    "JumpServerClient_5.1.1_x64-setup.exe",
  );
  assert.equal(
    readlinkSync(path.join(root, "public/Client_5.1.1_aarch64.dmg")),
    "JumpServerClient_5.1.1_aarch64.dmg",
  );
  assert.ok(
    readFileSync(path.join(root, "applets/JumpServer-WebLite-5.2.0-x64.msi"), "utf8").includes(
      "weblite-v5.2.0",
    ),
  );
});

test("explicit legacy tags keep downloads working before new product releases exist", (context) => {
  const { urls } = download(context, pinned);
  assert.deepEqual(urls, [
    "https://github.com/jumpserver/luna/releases/download/v5.1.0-rc3/JumpServer-5.1.0-rc3-Setup.exe",
    "https://github.com/jumpserver/luna/releases/download/v5.1.0-rc3/JumpServer-5.1.0-rc3-arm64.dmg",
    "https://github.com/jumpserver/luna/releases/download/v5.1.0-rc3/JumpServer-WebLite-5.1.0-rc3-x64.msi",
  ]);
});
