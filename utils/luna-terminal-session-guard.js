/* Loaded synchronously before Luna boots by install-luna-terminal-guard.sh.
 * Chromium's background freezing policy exempts pages holding Web Locks.
 * This is a background-freeze mitigation, not SSH session persistence.
 */
;(() => {
  'use strict'

  if (window.__jmsTerminalSessionGuard) return

  const supported = Boolean(navigator.locks?.request && window.WebSocket)
  let activeSockets = 0
  let heldLocks = 0
  let failures = 0
  Object.defineProperty(window, '__jmsTerminalSessionGuard', {
    value: Object.freeze({
      version: 1,
      supported,
      get activeSockets() {
        return activeSockets
      },
      get heldLocks() {
        return heldLocks
      },
      get failures() {
        return failures
      }
    })
  })

  if (!supported) {
    console.warn('JumpServer: Web Locks unavailable; terminal freeze protection is inactive.')
    return
  }

  function protect(socket) {
    const controller = new AbortController()
    let finished = false
    let releaseLock
    activeSockets += 1

    // Each socket gets a shared lock: other terminals/tabs never wait for it.
    // Request while CONNECTING, so slow handshakes are protected as well.
    const finish = () => {
      if (finished) return
      finished = true
      activeSockets -= 1
      controller.abort()
      releaseLock?.()
    }
    socket.addEventListener('close', finish, { once: true })

    try {
      navigator.locks
        .request(
          'jumpserver:koko:active-terminal',
          { mode: 'shared', signal: controller.signal },
          () => {
            if (finished) return
            heldLocks += 1
            return new Promise((resolve) => {
              releaseLock = () => {
                heldLocks -= 1
                resolve()
              }
            })
          }
        )
        .catch((error) => {
          if (error?.name === 'AbortError' && finished) return
          failures += 1
          console.warn('JumpServer: terminal freeze protection could not acquire a Web Lock.')
        })
    } catch {
      failures += 1
      console.warn('JumpServer: terminal freeze protection could not request a Web Lock.')
    }
  }

  const NativeWebSocket = window.WebSocket
  window.WebSocket = new Proxy(NativeWebSocket, {
    construct(target, args, newTarget) {
      const socket = Reflect.construct(target, args, newTarget)
      // Use the native normalized URL; never stringify application arguments
      // twice, change protocols, or intercept terminal data.
      if (/^\/koko\/ws\/terminal\/?$/.test(new URL(socket.url).pathname)) {
        protect(socket)
      }
      return socket
    }
  })
})()
