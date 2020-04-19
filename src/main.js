import { Elm } from './Main.elm'

const pageUrl = `${window.location.protocol}:${window.location.hostname}`

let token = null
try {
  token = window.localStorage.getItem("token") || null
} catch (err) {
  window.console.error(err)
}

const app = Elm.Main.init({
  flags: process.env.NODE_ENV === "development"
    ? { apiUrl: "http://localhost:8080", pageUrl, token }
    : { apiUrl: window.location.host, pageUrl, token }
})

app.ports.storeToken.subscribe((token) => {
  try {
    if (window.localStorage) window.localStorage.setItem("token", token)
  } catch (err) {
    window.console.error(err)
  }
})

if (window.location.search.includes("code")) {
  setTimeout(function () {
    window.history.replaceState(null, document.title, "/")
  }, 0)
}
