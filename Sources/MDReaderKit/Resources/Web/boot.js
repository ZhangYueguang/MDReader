const nativeBridge = globalThis.webkit?.messageHandlers?.reader

function postToNative(message) {
  nativeBridge?.postMessage(message)
}

function reportReady() {
  if (!globalThis.MDReader?.render) {
    postToNative({type: 'error', message: 'The Markdown renderer failed to start.'})
    return
  }
  postToNative({type: 'ready'})
}

globalThis.addEventListener('DOMContentLoaded', reportReady, {once: true})
globalThis.addEventListener('unhandledrejection', event => {
  const message = event.reason instanceof Error
    ? event.reason.message
    : 'An error occurred while typesetting the document.'
  postToNative({type: 'error', message})
})
