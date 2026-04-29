use std::env;
use std::process::Command;

fn git_output(args: &[&str]) -> Option<String> {
    let output = Command::new("git").args(args).output().ok()?;

    if !output.status.success() {
        return None;
    }

    let value = String::from_utf8(output.stdout).ok()?;
    let trimmed = value.trim();

    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed.to_owned())
    }
}

fn main() {
    println!("cargo:rerun-if-changed=.git/HEAD");
    println!("cargo:rerun-if-changed=.git/packed-refs");
    println!("cargo:rerun-if-changed=.git/refs");
    println!("cargo:rerun-if-env-changed=CARGO_PKG_VERSION");

    let package_version = env::var("CARGO_PKG_VERSION").expect("CARGO_PKG_VERSION must be set");
    let release_tag = format!("v{}", package_version);

    let display_version = match (
        git_output(&["rev-parse", "--short=12", "HEAD"]),
        git_output(&["describe", "--exact-match", "--tags", "HEAD"]),
    ) {
        (Some(_), Some(tag)) if tag == release_tag => package_version,
        (Some(commit), _) => format!("{}+git.{}", package_version, commit),
        _ => package_version,
    };

    println!(
        "cargo:rustc-env=WIFI_CONNECT_DISPLAY_VERSION={}",
        display_version
    );
}
