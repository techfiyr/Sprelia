/*
 * Hermione sing-along stage (first-party, no dependencies, no network).
 * Words are lit by CSS; this only (re)starts the light-up. Without JavaScript every word is simply lit.
 * Reduced motion: everything stays lit and nothing animates.
 */
(function () {
  var root = document.documentElement;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce) return;
  root.classList.add('js');

  function sing(line) {
    line.classList.remove('sing');
    void line.offsetWidth; // restart the animation
    line.classList.add('sing');
  }

  function ready() {
    var lines = document.querySelectorAll('.line');
    // The hero sings immediately; the rest sing as they scroll into view.
    document.querySelectorAll('.stage-hero .line').forEach(function (l) { l.classList.add('sing'); });
    if (!('IntersectionObserver' in window)) {
      lines.forEach(function (l) { l.classList.add('sing'); });
    } else {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { e.target.classList.add('sing'); io.unobserve(e.target); }
        });
      }, { threshold: 0.6 });
      lines.forEach(function (l) { if (!l.classList.contains('sing')) io.observe(l); });
    }
    document.querySelectorAll('[data-sing]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var line = btn.querySelector('.line') || btn;
        sing(line);
        var live = document.getElementById('stage-status');
        if (live) live.textContent = 'Playing: ' + btn.textContent.trim().replace(/\s+/g, ' ');
      });
    });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', ready); else ready();
})();
