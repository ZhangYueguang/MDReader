import AppKit
import Foundation
import MDReaderKit
@preconcurrency import WebKit

// Opt-in real WebKit test: npm run build:web && swift run MDReaderTests --web-images
@MainActor
func runReaderImageIntegrationTest() throws {
  _ = NSApplication.shared
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }
  let notes = root.appendingPathComponent("notes")
  try FileManager.default.createDirectory(at: notes, withIntermediateDirectories: true)
  let absoluteImage = root.appendingPathComponent("中文 图片.gif")
  try Data(base64Encoded: "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")!
    .write(to: absoluteImage)
  let svg = Data(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"120\" height=\"60\"><rect width=\"120\" height=\"60\" fill=\"teal\"/></svg>"
      .utf8)
  for filename in ["plain.svg", "中文 图.svg", "100%#?.svg", "literal%20.svg"] {
    try svg.write(to: notes.appendingPathComponent(filename))
  }
  var source = """
    ![Plain](plain.svg)

    ![Chinese](<中文 图.svg>)

    <img alt="HTML" src="中文 图.svg">

    ![Reserved](100%25%23%3F.svg)

    ![Literal](literal%2520.svg)

    ![Suffix](plain.svg?v=1#preview)

    ![Embedded](data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7)

    ![Reference][picture]

    [picture]: plain.svg

    ![Absolute](<\(absoluteImage.path)>)

    ![File URL](\(absoluteImage.absoluteString))

    <img alt="Absolute HTML" src="\(absoluteImage.path)">
    """
  let includeRemote = CommandLine.arguments.contains("--remote-images")
  if includeRemote {
    source +=
      "\n\n![Remote](https://raw.githubusercontent.com/ZhangYueguang/MDReader/main/Assets/MDReaderIcon.png)"
  }
  var count = includeRemote ? 12 : 11
  var documentDirectory = notes
  if let index = CommandLine.arguments.firstIndex(of: "--image-document"),
    CommandLine.arguments.indices.contains(index + 1),
    let countIndex = CommandLine.arguments.firstIndex(of: "--expected-images"),
    CommandLine.arguments.indices.contains(countIndex + 1),
    let expected = Int(CommandLine.arguments[countIndex + 1])
  {
    let documentURL = URL(fileURLWithPath: CommandLine.arguments[index + 1])
    source = try String(contentsOf: documentURL, encoding: .utf8)
    documentDirectory = documentURL.deletingLastPathComponent()
    count = expected
  }
  let bridge = ImageTestBridge(source: source, count: count)
  let config = WKWebViewConfiguration()
  let handler = ReaderSchemeHandler(documentDirectory: documentDirectory)
  config.setURLSchemeHandler(handler, forURLScheme: "mdreader-resource")
  config.setURLSchemeHandler(handler, forURLScheme: "mdreader-file")
  config.userContentController.add(bridge, name: "reader")
  let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700), configuration: config)
  bridge.view = view
  view.load(URLRequest(url: URL(string: "mdreader-resource://app/index.html")!))
  let deadline = Date().addingTimeInterval(30)
  while bridge.result == nil && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
  }
  defer { config.userContentController.removeScriptMessageHandler(forName: "reader") }
  guard let result = bridge.result else { throw TestFailure("WebKit image test timed out") }
  try expectEqual(result, "PASS:\(count)")
  print("PASS WebKit decoded all \(count) images using the bundled reader")
}

@MainActor
private final class ImageTestBridge: NSObject, WKScriptMessageHandler {
  let source: String
  let count: Int
  weak var view: WKWebView?
  var result: String?

  init(source: String, count: Int) {
    self.source = source
    self.count = count
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let body = message.body as? [String: Any], let type = body["type"] as? String else {
      return
    }
    if type == "image-test" || type == "error" {
      result = body["message"] as? String ?? "Unknown rendering error"
    } else if type == "ready" {
      Task {
        do {
          _ = try await view?.callAsyncJavaScript(
            """
            await window.MDReader.render({source, title: 'Image test'});
            const images = [...document.querySelectorAll('#content img')];
            await Promise.all(images.map(image => image.complete ? null : new Promise(resolve => {
              image.addEventListener('load', resolve, {once: true});
              image.addEventListener('error', resolve, {once: true});
            })));
            const ok = images.length === count && images.every(image => image.naturalWidth > 0)
              && !document.querySelector('.broken-image');
            window.webkit.messageHandlers.reader.postMessage({type: 'image-test',
              message: ok ? `PASS:${count}` : JSON.stringify({
                expected: count, loaded: images.filter(image => image.naturalWidth > 0).length,
                failed: [...document.querySelectorAll('.broken-image')].map(node => node.textContent)
              })});
            """, arguments: ["source": source, "count": count], in: nil, contentWorld: .page)
        } catch { result = error.localizedDescription }
      }
    }
  }
}
