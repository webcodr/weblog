!(function (e) {
  var t = {};
  function r(n) {
    if (t[n]) return t[n].exports;
    var o = (t[n] = { i: n, l: !1, exports: {} });
    return e[n].call(o.exports, o, o.exports, r), (o.l = !0), o.exports;
  }
  (r.m = e),
    (r.c = t),
    (r.d = function (e, t, n) {
      r.o(e, t) || Object.defineProperty(e, t, { enumerable: !0, get: n });
    }),
    (r.r = function (e) {
      "undefined" != typeof Symbol &&
        Symbol.toStringTag &&
        Object.defineProperty(e, Symbol.toStringTag, { value: "Module" }),
        Object.defineProperty(e, "__esModule", { value: !0 });
    }),
    (r.t = function (e, t) {
      if ((1 & t && (e = r(e)), 8 & t)) return e;
      if (4 & t && "object" == typeof e && e && e.__esModule) return e;
      var n = Object.create(null);
      if (
        (r.r(n),
        Object.defineProperty(n, "default", { enumerable: !0, value: e }),
        2 & t && "string" != typeof e)
      )
        for (var o in e)
          r.d(
            n,
            o,
            function (t) {
              return e[t];
            }.bind(null, o)
          );
      return n;
    }),
    (r.n = function (e) {
      var t =
        e && e.__esModule
          ? function () {
              return e.default;
            }
          : function () {
              return e;
            };
      return r.d(t, "a", t), t;
    }),
    (r.o = function (e, t) {
      return Object.prototype.hasOwnProperty.call(e, t);
    }),
    (r.p = ""),
    r((r.s = 3));
})([
  ,
  ,
  ,
  function (e, t, r) {
    e.exports = r(4);
  },
  function (e, t, r) {
    "use strict";
    r.r(t);
    var n = function () {
        var e = localStorage.getItem("preferredTheme");
        return e || o();
      },
      o = function () {
        var e = window.matchMedia("(prefers-color-scheme: dark)");
        return e && !0 === e.matches ? "dark" : "light";
      },
      c = function (e) {
        localStorage.setItem("preferredTheme", e),
          document.documentElement.setAttribute("data-theme", e);
      },
      a = function () {
        var e = "dark" === n() ? "light" : "dark";
        c(e),
          (document.querySelector("#toggle-checkbox").checked = "dark" === e);
      },
      u = { javascript: "JS", shell: "sh" };
    c(n()),
      document.addEventListener("DOMContentLoaded", function () {
        (document.querySelector("#toggle-checkbox").checked = "dark" === n()),
          document.querySelector("#theme-toggle").addEventListener("click", a),
          document
            .querySelector("#toggle-checkbox")
            .addEventListener("click", a),
          (function () {
            var e = document.querySelectorAll("[data-lang]");
            if (0 !== e.length) {
              var t,
                r = !0,
                n = !1,
                o = void 0;
              try {
                for (
                  var c, a = e[Symbol.iterator]();
                  !(r = (c = a.next()).done);
                  r = !0
                ) {
                  var l = c.value,
                    d = document.createElement("span"),
                    i = document.createTextNode(
                      ((t = l.getAttribute("data-lang")),
                      u[t.toLowerCase()] || t)
                    );
                  d.appendChild(i),
                    d.classList.add("post-content--language"),
                    l.prepend(d);
                }
              } catch (e) {
                (n = !0), (o = e);
              } finally {
                try {
                  r || null == a.return || a.return();
                } finally {
                  if (n) throw o;
                }
              }
            }
          })();
      });
  },
]);
