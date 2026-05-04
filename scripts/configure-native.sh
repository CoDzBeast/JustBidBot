#!/usr/bin/env bash
set -euo pipefail

mkdir -p android/app/src/main/java/com/lilzac/justbid
cat > android/app/src/main/java/com/lilzac/justbid/MainActivity.java <<'JAVA'
package com.lilzac.justbid;

import android.os.Bundle;
import android.webkit.WebView;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.WebViewListener;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends BridgeActivity {
    private String justBidInjectionScript;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        justBidInjectionScript = loadAsset("public/js/justbid-inject.js");
        bridge.addWebViewListener(new WebViewListener() {
            @Override
            public void onPageLoaded(WebView webView) {
                injectJustBidMod(webView);
            }
        });
    }

    private void injectJustBidMod(WebView webView) {
        if (justBidInjectionScript == null || justBidInjectionScript.isEmpty()) return;
        String wrappedScript = "(function(){"
            + "if(!/([^.]\\.)?justbid\\.com$/i.test(location.hostname)){return;}"
            + justBidInjectionScript
            + "})();";
        webView.post(() -> webView.evaluateJavascript(wrappedScript, null));
    }

    private String loadAsset(String path) {
        try (InputStream input = getAssets().open(path);
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            int read;
            while ((read = input.read(buffer)) != -1) output.write(buffer, 0, read);
            return output.toString(StandardCharsets.UTF_8.name());
        } catch (IOException error) {
            return "";
        }
    }
}
JAVA

mkdir -p ios/App/App
cat > ios/App/App/MainViewController.swift <<'SWIFT'
import Capacitor
import UIKit
import WebKit

class MainViewController: CAPBridgeViewController {
    private static let sharedProcessPool = WKProcessPool()

    override func webViewConfiguration(for instanceConfiguration: InstanceConfiguration) -> WKWebViewConfiguration {
        let configuration = super.webViewConfiguration(for: instanceConfiguration)
        configuration.processPool = MainViewController.sharedProcessPool
        return configuration
    }

    override func capacitorDidLoad() {
        super.capacitorDidLoad()
        installJustBidInjectionScript()
    }

    private func installJustBidInjectionScript() {
        guard
            let scriptPath = Bundle.main.path(forResource: "justbid-inject", ofType: "js", inDirectory: "public/js"),
            let scriptBody = try? String(contentsOfFile: scriptPath, encoding: .utf8)
        else { return }

        let guardedScript = """
        (function() {
          if (!/([^.]\\.)?justbid\\.com$/i.test(location.hostname)) { return; }
          \(scriptBody)
        })();
        """

        let userScript = WKUserScript(source: guardedScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView?.configuration.userContentController.addUserScript(userScript)
        webView?.evaluateJavaScript(guardedScript, completionHandler: nil)
    }
}
SWIFT

python3 <<'PY'
from pathlib import Path

gradle = Path("android/app/build.gradle")
if gradle.exists():
    text = gradle.read_text()
    if "JUSTBID_ANDROID_KEYSTORE" not in text:
        text = text.replace("    buildTypes {\n", """    signingConfigs {
        release {
            if (project.hasProperty('JUSTBID_ANDROID_KEYSTORE')) {
                storeFile file(project.property('JUSTBID_ANDROID_KEYSTORE'))
                storePassword project.property('JUSTBID_ANDROID_KEYSTORE_PASSWORD')
                keyAlias project.property('JUSTBID_ANDROID_KEY_ALIAS')
                keyPassword project.property('JUSTBID_ANDROID_KEY_PASSWORD')
            }
        }
    }
    buildTypes {
""")
        text = text.replace("        release {\n            minifyEnabled false\n", """        release {
            minifyEnabled false
            if (project.hasProperty('JUSTBID_ANDROID_KEYSTORE')) {
                signingConfig signingConfigs.release
            }
""")
        gradle.write_text(text)

storyboard = Path("ios/App/App/Base.lproj/Main.storyboard")
if storyboard.exists():
    text = storyboard.read_text()
    text = text.replace('customClass="CAPBridgeViewController" customModule="Capacitor"', 'customClass="MainViewController" customModule="App" customModuleProvider="target"')
    storyboard.write_text(text)

pbx = Path("ios/App/App.xcodeproj/project.pbxproj")
if pbx.exists():
    text = pbx.read_text()
    if "MainViewController.swift" not in text:
        text = text.replace("504EC3081FED79650016851F /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 504EC3071FED79650016851F /* AppDelegate.swift */; };", "504EC3081FED79650016851F /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 504EC3071FED79650016851F /* AppDelegate.swift */; };\n\t\t504EC3191FED79650016851F /* MainViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = 504EC31A1FED79650016851F /* MainViewController.swift */; };")
        text = text.replace("504EC3071FED79650016851F /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = \"<group>\"; };", "504EC3071FED79650016851F /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = \"<group>\"; };\n\t\t504EC31A1FED79650016851F /* MainViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MainViewController.swift; sourceTree = \"<group>\"; };")
        text = text.replace("\t\t\t\t504EC3071FED79650016851F /* AppDelegate.swift */,\n", "\t\t\t\t504EC3071FED79650016851F /* AppDelegate.swift */,\n\t\t\t\t504EC31A1FED79650016851F /* MainViewController.swift */,\n")
        text = text.replace("\t\t\t\t504EC3081FED79650016851F /* AppDelegate.swift in Sources */,\n", "\t\t\t\t504EC3081FED79650016851F /* AppDelegate.swift in Sources */,\n\t\t\t\t504EC3191FED79650016851F /* MainViewController.swift in Sources */,\n")
        pbx.write_text(text)
PY
