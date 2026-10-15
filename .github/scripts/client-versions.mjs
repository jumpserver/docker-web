const products = [
  {
    target: "client",
    key: "CLIENT",
    assets: (version) => [`JumpServer-${version}-Setup.exe`, `JumpServer-${version}-arm64.dmg`],
  },
  {
    target: "weblite",
    key: "WEBLITE",
    assets: (version) => [`JumpServer-WebLite-${version}-x64.msi`],
  },
];

function parseVersion(version) {
  const match = version.match(
    /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/,
  );
  if (!match) return null;
  const prerelease = match[4]?.split(".") || [];
  if (prerelease.some((part) => /^0\d+$/.test(part))) return null;
  return { release: match.slice(1, 4).map(BigInt), prerelease };
}

function compareVersions(a, b) {
  for (let i = 0; i < 3; i++) {
    if (a.release[i] !== b.release[i]) return a.release[i] > b.release[i] ? 1 : -1;
  }
  if (!a.prerelease.length || !b.prerelease.length) {
    return Number(!a.prerelease.length) - Number(!b.prerelease.length);
  }
  for (let i = 0; i < Math.max(a.prerelease.length, b.prerelease.length); i++) {
    const x = a.prerelease[i];
    const y = b.prerelease[i];
    if (x === y) continue;
    if (x === undefined || y === undefined) return x === undefined ? -1 : 1;
    const xNumeric = /^\d+$/.test(x);
    const yNumeric = /^\d+$/.test(y);
    if (xNumeric && yNumeric) return BigInt(x) > BigInt(y) ? 1 : -1;
    if (xNumeric !== yNumeric) return xNumeric ? -1 : 1;
    return x > y ? 1 : -1;
  }
  return 0;
}

function readSetting(content, key) {
  const matches = [...content.matchAll(new RegExp(`^${key}=([^\\r\\n]*)\\r?$`, "gm"))];
  if (matches.length !== 1) throw new Error(`Expected one ${key} in client-version.txt`);
  return matches[0][1];
}

export function updateClientVersions(content, releases) {
  for (const { target, key, assets } of products) {
    const currentVersion = readSetting(content, `${key}_VERSION`);
    const current = parseVersion(currentVersion);
    if (!current) {
      throw new Error(`Invalid ${key} version in client-version.txt`);
    }
    let selected;
    for (const release of releases) {
      if (release.draft || release.prerelease || !release.tag_name?.startsWith(`${target}-v`))
        continue;
      const version = release.tag_name.slice(`${target}-v`.length);
      const parsed = parseVersion(version);
      if (!parsed || compareVersions(parsed, current) < 0) continue;
      if (
        !assets(version).every((name) =>
          release.assets?.some((asset) => asset.name === name && asset.size > 0),
        )
      )
        continue;
      if (!selected || compareVersions(parsed, selected.parsed) > 0) {
        selected = { version, parsed };
      }
    }
    if (selected) {
      content = content.replace(
        new RegExp(`^${key}_VERSION=[^\\r\\n]*`, "m"),
        `${key}_VERSION=${selected.version}`,
      );
    }
  }
  return content;
}
