app_name := "ISPOrgMenuBarApp"
version := "1.1.1"
build_dir := ".build/arm64-apple-macosx/release"
release_dir := "release/" + version
app_bundle := release_dir + "/" + app_name + ".app"

_default:
    @just --list

build:
    swift build -c release

bundle: build
    mkdir -p {{app_bundle}}/Contents/MacOS
    mkdir -p {{app_bundle}}/Contents/Resources
    cp {{build_dir}}/{{app_name}} {{app_bundle}}/Contents/MacOS/
    cp Resources/Info.plist {{app_bundle}}/Contents/
    chmod +x {{app_bundle}}/Contents/MacOS/{{app_name}}

zip: bundle
    cd {{release_dir}} && zip -r {{app_name}}-{{version}}-macOS.zip {{app_name}}.app

install: bundle
    cp -R {{app_bundle}} /Applications/

clean:
    swift package clean
    rm -rf release/
    rm -rf .build
