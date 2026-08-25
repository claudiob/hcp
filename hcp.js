(function () {
  'use strict';
  var still = window.matchMedia('(prefers-reduced-motion: reduce)');

  /* ---- Ruby, highlighted by hand ---------------------------------------
     One pass, one alternation, longest-first where it matters: a comment
     swallows its line before a date inside it can be read as a number, and a
     string swallows a URL before its colons become symbols. The text itself is
     never rewritten, only wrapped, so copying still yields exactly what the
     README says. */
  var RUBY = new RegExp([
    '(#[^\\n]*)',                                             /* comment */
    "('(?:\\\\.|[^'\\\\])*'|\"(?:\\\\.|[^\"\\\\])*\")",       /* string */
    '(\\b\\d+(?:\\.\\d+)?\\b)',                               /* number */
    '([a-z_][A-Za-z0-9_]*:(?!:))',                            /* symbol key */
    '(\\b(?:do|end|def|class|module|require|rescue|begin|nil|true|false|self|if|else|return)\\b)',
    '(\\b[A-Z][A-Za-z0-9_]*)',                                /* constant */
    '(\\.[A-Za-z_][A-Za-z0-9_]*[?!]?)',                       /* method call */
    '(\\b[a-z_][A-Za-z0-9_]*[?!]?)',                          /* plain name */
    '([{}()\\[\\]<>=|&+\\-*/%!?:,.]+)'                        /* punctuation */
  ].join('|'), 'g');
  var CLASSES = ['c', 's', 'n', 'y', 'k', 't', 'm', '', 'p'];

  function esc(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function paint(src) {
    var out = '', last = 0, hit, group, cls;
    RUBY.lastIndex = 0;
    while ((hit = RUBY.exec(src)) !== null) {
      if (hit.index > last) { out += esc(src.slice(last, hit.index)); }
      cls = '';
      for (group = 1; group < hit.length; group++) {
        if (hit[group] !== undefined) { cls = CLASSES[group - 1]; break; }
      }
      if (cls === 'm') {
        out += '<span class="p">.</span><span class="m">' + esc(hit[0].slice(1)) + '</span>';
      } else if (cls) {
        out += '<span class="' + cls + '">' + esc(hit[0]) + '</span>';
      } else {
        out += esc(hit[0]);
      }
      last = hit.index + hit[0].length;
    }
    return out + esc(src.slice(last));
  }

  /* ---- Copy, with a socket that seats ---------------------------------- */
  var SOCKET = '<svg viewBox="0 0 16 16" aria-hidden="true">' +
    '<path class="socket" d="M8 1.4 13.7 4.7v6.6L8 14.6 2.3 11.3V4.7z"/>' +
    '<path class="socket" d="M8 5 11 6.7v3.4L8 11.8 5 10.1V6.7z"/></svg>';

  var blocks = document.querySelectorAll('.snippet');
  Array.prototype.forEach.call(blocks, function (block) {
    var code = block.querySelector('code');
    var source = code.textContent;
    code.innerHTML = paint(source);

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'copy';
    button.innerHTML = SOCKET + '<span>Copy</span>';
    var label = button.querySelector('span');
    var revert;

    button.addEventListener('click', function () {
      function seated() {
        button.classList.add('done');
        label.textContent = 'Copied';
        window.clearTimeout(revert);
        revert = window.setTimeout(function () {
          button.classList.remove('done');
          label.textContent = 'Copy';
        }, 1800);
      }
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(source).then(seated, fallback);
      } else {
        fallback();
      }
      /* Insecure origins and older Safari get the textarea trick instead, so
         "Copy" is never a button that quietly does nothing. */
      function fallback() {
        var pad = document.createElement('textarea');
        pad.value = source;
        pad.setAttribute('readonly', '');
        pad.style.cssText = 'position:fixed;top:-1000px;opacity:0';
        document.body.appendChild(pad);
        pad.select();
        try { document.execCommand('copy'); seated(); } catch (nope) { label.textContent = 'Select it'; }
        document.body.removeChild(pad);
      }
    });

    block.appendChild(button);
  });

  /* ---- The level -------------------------------------------------------- */
  var bubble = document.getElementById('bubble');
  var pending = false;

  function settle() {
    pending = false;
    var run = document.documentElement.scrollHeight - window.innerHeight;
    var read = run > 0 ? Math.min(1, window.scrollY / run) : 0;
    bubble.style.left = 'calc(' + (read * 100) + '% - ' + (read * 34) + 'px)';
  }

  function onScroll() {
    if (pending) { return; }
    pending = true;
    window.requestAnimationFrame(settle);
  }

  if (bubble && !still.matches) {
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    settle();
  }

  /* ---- Sections settle into place as they come up ----------------------- */
  var sections = document.querySelectorAll('main section');
  if (still.matches || !('IntersectionObserver' in window)) {
    Array.prototype.forEach.call(sections, function (s) { s.classList.add('seen'); });
  } else {
    var watcher = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) { return; }
        entry.target.classList.add('seen');
        watcher.unobserve(entry.target);
      });
    }, { rootMargin: '0px 0px -12% 0px' });
    Array.prototype.forEach.call(sections, function (s) { watcher.observe(s); });
  }
})();
