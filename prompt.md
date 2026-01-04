# PRINCIPIOS DE CODIFICACIÓN
- Asignar nombres descriptivos a las variables, incluso cuando se realizan iteraciones.
- Encapsular lógica mínima en métodos/componentes con nombres descriptivos y responsabilidades claramente definidas.
- Aplicar DRY para reutilizar métodos/componentes.
- No añadas comentarios en el código fuente.
- Durante una refactorización tomar la libertad de:
  - Renombrar variables/métodos/componentes a fin de mantener nombres coherentes y descriptivos.
  - Eliminar variables/métodos/componentes en desuso.

---

# SOLICITUD

Te proporcionaré el código fuente web de mi aplicación a fin de analizarlo exhaustivamente para brindar solución a los siguientes requerimientos:

- Gestión de gastos (Actualición y nuevo gasto - verificación de límite)
  - Se ha actualizado la respuesta de los servicios backend `ExpenseUpdateService` y `ExpenseSaveService` para que retornen `ExpenseUpdateResponseDto` y `ExpenseSaveResponseDto` respectivamente, en las cuales está incluido el campo isBelowLimit.
  - La razón del cambio es que si isBelowLimit es false, entonces hay que mostrar un mensaje de warning indicando que se superó el límite mensual para la categoría seleccionada.
  - Este mensaje de warning no debe cerrarse automáticamente, sino es el usuario es quien debe hacerlo.
  - En este sentido, hay que actualizar la UI para que reciba correctamente los objetos Dto y aplique el comportamiento mencionado.

Bríndame el código fuente de todos los componentes en un archivo .zip con los archivos modificados/añadidos.

---

```
.
├── src/
│   ├── main/
│   │   ├── commons/
│   │   │   ├── constants/
│   │   │   │   ├── AppConstants.ts
│   │   │   │   ├── Categories.ts
│   │   │   │   ├── DateConstants.ts
│   │   │   │   ├── Props.ts
│   │   │   │   ├── Strings.ts
│   │   │   │   └── WebAction.ts
│   │   │   ├── gmail/
│   │   │   │   ├── mapper/
│   │   │   │   │   └── EmailMapper.ts
│   │   │   │   └── repository/
│   │   │   │       ├── wrapper/
│   │   │   │       │   └── EmailWrapper.ts
│   │   │   │       └── GmailRepository.ts
│   │   │   ├── properties/
│   │   │   │   ├── ApplicationProperties.ts
│   │   │   │   └── Properties.ts
│   │   │   ├── trigger/
│   │   │   │   └── Trigger.ts
│   │   │   ├── utils/
│   │   │   │   └── TimeUtil.ts
│   │   │   └── view/
│   │   │       └── ExpenseView.ts
│   │   ├── entrypoint/
│   │   │   ├── expenses/
│   │   │   │   ├── dto/
│   │   │   │   │   └── response/
│   │   │   │   │       ├── ExpenseSaveResponseDto.ts
│   │   │   │   │       └── ExpenseUpdateResponseDto.ts
│   │   │   │   ├── helper/
│   │   │   │   │   └── ExpenseLimitValidator.ts
│   │   │   │   ├── repository/
│   │   │   │   │   ├── entity/
│   │   │   │   │   │   ├── ExpenseEntity.ts
│   │   │   │   │   │   └── ExpenseIndex.ts
│   │   │   │   │   └── ExpenseRepository.ts
│   │   │   │   └── service/
│   │   │   │       ├── ExpenseSaveService.ts
│   │   │   │       └── ExpenseUpdateService.ts
│   │   │   └── proof-of-payment
│   │   └── index.ts
│   ├── web/
│   │   ├── AppCommon.html
│   │   ├── AppConfig.html
│   │   ├── AppSave.html
│   │   ├── AppSearch.html
│   │   ├── AppUpdate.html
│   │   ├── Header.html
│   │   ├── Index.html
│   │   ├── ToastsAndModals.html
│   │   ├── ViewSave.html
│   │   ├── ViewSearch.html
│   │   └── ViewUpdate.html
│   ├── appsscript.json
│   └── main.gs
├── .clasp.json
├── .eslintrc.cjs
├── .gitignore
├── .prettierrc
├── README.md
├── build.mjs
├── package-lock.json
├── package.json
├── tsconfig.gaslocal.json
└── tsconfig.json
```

---

` /src/web/AppCommon.html`
```
<script>
  (function () {
    var initialAction = "<?= initialTab || 'search' ?>";
    if (!['search', 'save', 'update'].includes(initialAction)) initialAction = 'search';

    var initialUpdate = {
      gmailMessageId: "<?= gmailMessageId || '' ?>",
      amount: "<?= amount || '' ?>",
      currency: "<?= currency || '' ?>",
      expenseDate: "<?= expenseDate || '' ?>",
      source: "<?= source || '' ?>",
      comments: "<?= comments || '' ?>",
      category: "<?= category || '' ?>",
    };

    var currencies = JSON.parse('<?= JSON.stringify(currencies) ?>');
    var initialCategories = JSON.parse('<?= JSON.stringify(categories || []) ?>');

    function normalizeCode(v) { return String(v || '').trim().toUpperCase(); }
    function normalizeText(v) { return String(v || '').trim(); }

    function buildCurrencyMap(list) {
      var map = {};
      for (var i = 0; i < list.length; i++) {
        var c = list[i] || {};
        map[normalizeCode(c.code)] = String(c.symbol || '');
      }
      return map;
    }

    var currencyMap = buildCurrencyMap(currencies);
    function $(id) { return document.getElementById(id); }

    var loaderEl;
    var themeBtn;

    function showLoader(show) {
      if (!loaderEl) loaderEl = $('globalLoader');
      if (!loaderEl) return;
      loaderEl.classList.toggle('hidden', !show);
      loaderEl.classList.toggle('flex', !!show);
    }

    function setBusy(btn, busy) {
      if (!btn) return;
      btn.disabled = !!busy;
      btn.setAttribute('aria-busy', busy ? 'true' : 'false');
    }

    function setButtonLoading(btn, loading, options) {
      if (!btn) return;
      var opts = options || {};
      var busy = !!loading;

      if (!btn.getAttribute('data-original-html')) btn.setAttribute('data-original-html', btn.innerHTML);

      if (!busy) {
        var original = btn.getAttribute('data-original-html');
        if (original != null) btn.innerHTML = original;
        btn.removeAttribute('data-loading');
        btn.setAttribute('aria-busy', 'false');
        return;
      }

      var label = String(opts.label || 'Guardando...');
      var spinnerClass = String(opts.spinnerClass || 'fa-solid fa-circle-notch fa-spin');
      btn.innerHTML = '<i class="' + spinnerClass + '"></i> ' + label;
      btn.setAttribute('data-loading', 'true');
      btn.setAttribute('aria-busy', 'true');
    }

    function setModalBusy(modalId, busy) {
      var el = $(modalId);
      if (!el) return;
      el.setAttribute('data-busy', busy ? 'true' : 'false');

      var controls = el.querySelectorAll('input, select, textarea, button');
      controls.forEach(function (c) {
        if (c && c.getAttribute && c.getAttribute('data-close-modal')) return;
        c.disabled = !!busy;
        c.setAttribute('aria-busy', busy ? 'true' : 'false');
      });
    }

    function setModalLoading(modalId, loading) {
      var el = $(modalId);
      if (!el) return;
      var loader = el.querySelector('[data-modal-loader="true"]');
      var content = el.querySelector('[data-modal-content="true"]');
      if (loader) loader.classList.toggle('hidden', !loading);
      if (content) content.classList.toggle('hidden', !!loading);
      el.setAttribute('data-loading', loading ? 'true' : 'false');
    }

    function initSidebarHover() {
      var sidebar = $('desktopSidebar');
      if (!sidebar) return;

      var expandTimer = null;

      function setExpanded(expanded) {
        sidebar.classList.toggle('md:w-56', expanded);
        sidebar.classList.toggle('md:w-[72px]', !expanded);

        var labels = sidebar.querySelectorAll('[data-sidebar-label]');
        labels.forEach(function (l) { l.classList.toggle('hidden', !expanded); });

        var logo = sidebar.querySelector('[data-sidebar-logo-text]');
        if (logo) logo.classList.toggle('hidden', !expanded);
      }

      function onEnter() {
        window.clearTimeout(expandTimer);
        expandTimer = window.setTimeout(function () { setExpanded(true); }, 1000);
      }

      function onLeave() {
        window.clearTimeout(expandTimer);
        setExpanded(false);
      }

      sidebar.addEventListener('mouseenter', onEnter);
      sidebar.addEventListener('mouseleave', onLeave);

      var expensesBtn = sidebar.querySelector('[data-nav="expenses"]');
      if (expensesBtn) {
        expensesBtn.addEventListener('click', function () {
          var btn = $('tab-search-btn');
          if (btn) btn.click();
          syncSideButtons('search');
        });
      }

      var loansBtn = sidebar.querySelector('[data-nav="loans"]');
      if (loansBtn) {
        loansBtn.addEventListener('click', function () {
          toast('Gestión de préstamos estará disponible próximamente.', false);
        });
      }

      setExpanded(false);
    }

    function initBottomNav() {
      var nav = $('mobileBottomNav');
      if (!nav) return;

      function setActive(key) {
        var buttons = nav.querySelectorAll('[data-bottom-nav]');
        buttons.forEach(function (btn) {
          var isActive = btn.getAttribute('data-bottom-nav') === key;
          btn.classList.toggle('text-gray-900', isActive);
          btn.classList.toggle('dark:text-gray-100', isActive);
          btn.classList.toggle('text-gray-600', !isActive);
          btn.classList.toggle('dark:text-gray-300', !isActive);
          btn.classList.toggle('bg-gray-100', isActive);
          btn.classList.toggle('dark:bg-gray-900', isActive);
        });
      }

      nav.addEventListener('click', function (e) {
        var t = e && e.target;
        if (!t || !t.closest) return;
        var btn = t.closest('[data-bottom-nav]');
        if (!btn) return;

        var key = btn.getAttribute('data-bottom-nav');
        if (key === 'expenses') {
          setActive('expenses');
          var tabBtn = $('tab-search-btn');
          if (tabBtn) tabBtn.click();
          return;
        }

        if (key === 'loans') toast('Gestión de préstamos estará disponible próximamente.', false);
        if (key === 'investments') toast('Inversiones estará disponible próximamente.', false);
      });

      setActive('expenses');
    }

    var modalInstances = {};

    function ensureModal(modalId, opts) {
      if (!modalId) return null;
      if (modalInstances[modalId]) return modalInstances[modalId];

      var el = $(modalId);
      if (!el || !window.Modal) return null;

      try {
        var instance = new window.Modal(el, opts || { backdrop: 'dynamic', closable: true });
        modalInstances[modalId] = instance;
        return instance;
      } catch (e) {
        return null;
      }
    }

    function openModal(modalId) {
      var modal = ensureModal(modalId);
      if (!modal) return;
      modal.show();
    }

    function closeModal(modalId) {
      var el = $(modalId);
      if (el && (el.getAttribute('data-busy') === 'true' || el.getAttribute('data-loading') === 'true')) return;

      var modal = ensureModal(modalId);
      if (!modal) return;
      try { modal.hide(); } catch (e) {}
    }

    function toast(msg, ok) {
      var modalEl = $('statusModal');
      if (!modalEl) return;

      var iconEl = $('statusModalIcon');
      var msgEl = $('statusModalMessage');

      if (iconEl) {
        iconEl.className = 'fa-solid ' + (ok ? 'fa-circle-check' : 'fa-circle-xmark') + ' text-2xl';
      }
      if (msgEl) msgEl.textContent = msg || '';

      var modal = ensureModal('statusModal', { backdrop: 'dynamic', closable: true });
      if (!modal) return;
      modal.show();

      window.clearTimeout(window.__statusModalTimer);
      window.__statusModalTimer = window.setTimeout(function () {
        try { modal.hide(); } catch (e) {}
      }, 1800);
    }

    function setTheme(mode) {
      var dark = mode === 'dark';
      document.documentElement.classList.toggle('dark', dark);
      var icon = '<i class="fa-solid ' + (dark ? 'fa-sun' : 'fa-moon') + '"></i>';
      if (themeBtn) themeBtn.innerHTML = icon;
    }

    function initThemeToggle() {
      themeBtn = $('themeToggle');

      var saved = localStorage.getItem('dex_theme') || 'light';
      setTheme(saved);

      function onToggle() {
        var current = document.documentElement.classList.contains('dark') ? 'dark' : 'light';
        var next = current === 'dark' ? 'light' : 'dark';
        localStorage.setItem('dex_theme', next);
        setTheme(next);
      }

      if (themeBtn) themeBtn.addEventListener('click', onToggle);
    }

    function syncSideButtons(activeKey) {
      var side = document.querySelectorAll('aside [data-tab-key]');
      side.forEach(function (b) {
        var isActive = b.getAttribute('data-tab-key') === activeKey;
        b.classList.toggle('bg-gray-50', isActive);
        b.classList.toggle('text-gray-900', isActive);
        b.classList.toggle('dark:bg-gray-900', isActive);
        b.classList.toggle('dark:text-white', isActive);
      });
    }

    function initTabSync() {
      document.addEventListener('shown.tw.tab', function (e) {
        try {
          var target = e && e.target ? e.target.getAttribute('data-tabs-target') : '';
          var key = target === '#tab-search' ? 'search' : 'search';
          syncSideButtons(key);
        } catch (err) {}
      });

      var btn = $('tab-search-btn');
      if (btn) btn.click();
      syncSideButtons('search');
    }

    function normalizeNumberString(v) { return String(v == null ? '' : v).replace(',', '.').trim(); }
    function isNumeric(v) { var n = Number(normalizeNumberString(v)); return !isNaN(n); }
    function isNumericOrEmpty(v) { var s = normalizeNumberString(v); if (!s) return true; var n = Number(s); return !isNaN(n); }

    var PositiveDecimal = (function () {
      var REGEX = /^\d+(\.\d+)?$/;

      function sanitize(value) {
        if (value == null) return "";
        var out = String(value).replace(/[^\d.]/g, "");
        var firstDot = out.indexOf(".");
        if (firstDot !== -1) {
          out = out.substring(0, firstDot + 1) + out.substring(firstDot + 1).replace(/\./g, "");
        }
        out = out.replace(/^\./, "");
        return out;
      }

      function bind(inputOrSelector) {
        var input = (typeof inputOrSelector === "string") ? document.querySelector(inputOrSelector) : inputOrSelector;
        if (!input) return;

        function handler() {
          var sanitized = sanitize(input.value);
          if (input.value !== sanitized) {
            var start = input.selectionStart;
            var end = input.selectionEnd;
            input.value = sanitized;
            try { input.setSelectionRange(start, end); } catch (e) {}
          }
          if (input.value === "" || REGEX.test(input.value)) input.setCustomValidity("");
          else input.setCustomValidity("Ingrese un número positivo");
        }

        input.addEventListener("input", handler);
        input.addEventListener("blur", handler);
        handler();
      }

      function autoBind() {
        var inputs = document.querySelectorAll('input[data-positive-decimal="true"]');
        inputs.forEach(function (el) { bind(el); });
      }

      return Object.freeze({ REGEX: REGEX, sanitize: sanitize, bind: bind, autoBind: autoBind });
    })();

    function wireCreateButtons() {
      function openCreate() {
        if (window.AppCreate && window.AppCreate.open) window.AppCreate.open();
        else openModal('createExpenseModal');
      }

      var topBtn = $('openCreateModalTop');
      if (topBtn) topBtn.addEventListener('click', openCreate);

      var mobileBtn = $('openCreateModalMobile');
      if (mobileBtn) mobileBtn.addEventListener('click', openCreate);
    }

    function wireModalCloseButtons() {
      var btns = document.querySelectorAll('[data-close-modal]');
      btns.forEach(function (btn) {
        btn.addEventListener('click', function () {
          var modalId = btn.getAttribute('data-close-modal');
          closeModal(modalId);
        });
      });
    }

    function initModals() {
      ensureModal('statusModal', { backdrop: 'dynamic', closable: true });
      ensureModal('createExpenseModal', { backdrop: 'dynamic', closable: true });
      ensureModal('updateExpenseModal', { backdrop: 'dynamic', closable: true });
      ensureModal('configModal', { backdrop: 'dynamic', closable: true });
    }

    function normalizeCategoryResponse(res) {
      if (!res) return [];
      if (Array.isArray(res)) return res;
      if (res.categories && Array.isArray(res.categories)) return res.categories;
      return [];
    }

    function mapToCategoryItems(rawList) {
      return (rawList || []).map(function (c) {
        return { description: normalizeText(c.description), limit: Number(c.limit || 0) };
      }).filter(function (c) { return !!c.description; });
    }

    function applyCategoriesToSelect(select, list) {
      if (!select) return;

      var includeAll = select.hasAttribute('data-category-include-all');
      var includePlaceholder = select.hasAttribute('data-category-placeholder');

      var prev = String(select.value || '');
      select.innerHTML = '';

      if (includeAll) {
        var allOpt = document.createElement('option');
        allOpt.value = '';
        allOpt.textContent = 'Todas';
        select.appendChild(allOpt);
      }

      if (includePlaceholder) {
        var pl = document.createElement('option');
        pl.value = '';
        pl.textContent = 'Seleccione';
        pl.disabled = true;
        pl.selected = !prev;
        select.appendChild(pl);
      }

      for (var i = 0; i < (list || []).length; i++) {
        var opt = document.createElement('option');
        opt.value = list[i].description;
        opt.textContent = list[i].description;
        select.appendChild(opt);
      }

      if (prev) select.value = prev;
      if (!select.value && includePlaceholder) select.selectedIndex = 0;
    }

    var CategoriesStore = (function () {
      var cache = mapToCategoryItems(initialCategories);
      var loading = false;
      var pendingCallbacks = [];
      var lastFetchAt = 0;
      var MIN_REFRESH_MS = 15000;

      function list() { return cache.slice(); }

      function applyAll() {
        var selects = document.querySelectorAll('select[data-category-select="true"]');
        selects.forEach(function (s) { applyCategoriesToSelect(s, cache); });
      }

      function setCache(next, options) {
        var opts = options || {};
        cache = mapToCategoryItems(next || []);
        if (opts.apply) applyAll();
        if (opts.touchFetch) lastFetchAt = Date.now();
      }

      function loadFromBackend(done) {
        if (loading) {
          if (typeof done === 'function') pendingCallbacks.push(done);
          return;
        }

        loading = true;
        if (typeof done === 'function') pendingCallbacks.push(done);

        google.script.run
          .withSuccessHandler(function (res) {
            var next = mapToCategoryItems(normalizeCategoryResponse(res));
            setCache(next, { apply: true, touchFetch: true });

            loading = false;
            var cbs = pendingCallbacks.slice();
            pendingCallbacks = [];
            cbs.forEach(function (cb) { try { cb(list()); } catch (e) {} });
          })
          .withFailureHandler(function () {
            loading = false;
            var cbs = pendingCallbacks.slice();
            pendingCallbacks = [];
            cbs.forEach(function (cb) { try { cb(list()); } catch (e) {} });
          })
          .getCategories();
      }

      function ensureLoaded(done, options) {
        var opts = options || {};
        var force = !!opts.force;

        var now = Date.now();
        var freshEnough = cache && cache.length && (now - lastFetchAt) < MIN_REFRESH_MS;

        if (!force && freshEnough) {
          applyAll();
          if (typeof done === 'function') done(list());
          return;
        }

        loadFromBackend(function (out) {
          applyAll();
          if (typeof done === 'function') done(out);
        });
      }

      return Object.freeze({
        list: list,
        applyAll: applyAll,
        ensureLoaded: ensureLoaded,
        setCache: function (next, apply) { setCache(next, { apply: !!apply, touchFetch: true }); }
      });
    })();

    var Expenses = (function () {
      function toNumber(value) {
        var s = String(value == null ? '' : value).trim().replace(',', '.');
        if (!s) return NaN;
        var n = Number(s);
        return isNaN(n) ? NaN : n;
      }

      function findCategoryLimit(category) {
        var key = normalizeText(category);
        if (!key) return 0;
        var list = CategoriesStore.list();
        for (var i = 0; i < list.length; i++) {
          if (normalizeText(list[i].description) === key) return Number(list[i].limit || 0);
        }
        return 0;
      }

      function computeIsBelowLimit(amount, category) {
        var n = toNumber(amount);
        if (isNaN(n)) return false;
        var limit = findCategoryLimit(category);
        return n <= Number(limit || 0);
      }

      return Object.freeze({ computeIsBelowLimit: computeIsBelowLimit });
    })();

    window.AppUI = {
      initialAction: initialAction,
      initialUpdate: initialUpdate,

      currency: {
        list: currencies,
        normalizeCode: normalizeCode,
        defaultCode: function () { return normalizeCode(currencies[0] && currencies[0].code); },
        symbol: function (code) { return currencyMap[normalizeCode(code)]; }
      },

      categories: {
        list: function () { return CategoriesStore.list(); },
        applyAll: function () { CategoriesStore.applyAll(); },
        ensureLoaded: function (cb, opts) { CategoriesStore.ensureLoaded(cb, opts); },
        setCache: function (next, apply) { CategoriesStore.setCache(next, apply); }
      },

      expenses: Expenses,

      $: $,
      showLoader: showLoader,
      setBusy: setBusy,
      setButtonLoading: setButtonLoading,
      setModalBusy: setModalBusy,
      setModalLoading: setModalLoading,
      toast: toast,
      openModal: openModal,
      closeModal: closeModal,
      isNumeric: isNumeric,
      isNumericOrEmpty: isNumericOrEmpty,
      PositiveDecimal: PositiveDecimal,
      isPositiveDecimal: function (v) { return PositiveDecimal.REGEX.test(String(v || '').trim()); },
      isPositiveDecimalOrEmpty: function (v) {
        var s = String(v || '').trim();
        return s === '' || PositiveDecimal.REGEX.test(s);
      }
    };

    document.addEventListener('DOMContentLoaded', function () {
      loaderEl = $('globalLoader');
      initModals();
      initThemeToggle();
      initTabSync();
      wireCreateButtons();
      wireModalCloseButtons();
      initSidebarHover();
      initBottomNav();
      try { PositiveDecimal.autoBind(); } catch (e) {}

      if (window.AppUI && window.AppUI.categories && window.AppUI.categories.ensureLoaded) {
        window.AppUI.categories.ensureLoaded();
      }

      if (initialAction === 'save') {
        window.setTimeout(function () {
          if (window.AppCreate && window.AppCreate.open) window.AppCreate.open();
          else openModal('createExpenseModal');
        }, 0);
      }

      if (initialAction === 'update') {
        window.setTimeout(function () {
          if (window.AppUpdate && window.AppUpdate.openWithItem) window.AppUpdate.openWithItem(initialUpdate);
        }, 0);
      }
    });
  })();
</script>

```

---

` /src/web/AppSave.html`
```
<script>
  document.addEventListener('DOMContentLoaded', function () {
    var AppUI = window.AppUI;
    if (!AppUI) return;
    var $ = AppUI.$;

    var form = $('new-expense-form');
    if (!form) return;

    var saveBtn = $('saveBtn');

    var amountInput = $('amountInputSave');
    var categoryInput = $('categoryInputSave');
    var dateInput = $('dateInputSave');
    var commentsInput = $('commentsSave');
    var currencyInput = $('currencyInputSave');

    var touched = {};

    function markTouched(input) {
      if (!input || !input.id) return;
      touched[input.id] = true;
    }

    function setInvalidVisible(input, visible) {
      if (!input) return;
      var el = document.querySelector('[data-invalid-for="' + input.id + '"]');
      if (!el) return;
      el.classList.toggle('hidden', !visible);
    }

    function shouldShowInvalid(input) {
      if (!input) return false;
      return !!touched[input.id];
    }

    function syncValidation() {
      var inputs = [currencyInput, amountInput, dateInput, categoryInput];
      inputs.forEach(function (inp) {
        if (!inp) return;
        var show = shouldShowInvalid(inp) && !inp.checkValidity();
        setInvalidVisible(inp, show);
      });
      if (saveBtn) saveBtn.disabled = !form.checkValidity();
      return form.checkValidity();
    }

    function resetForm() {
      touched = {};

      amountInput.value = '';
      commentsInput.value = '';
      currencyInput.value = AppUI.currency.defaultCode();

      if (categoryInput) {
        categoryInput.value = '';
        if (categoryInput.options && categoryInput.options.length) categoryInput.selectedIndex = 0;
      }

      if (dateInput) dateInput.value = "<?= defaultDate ?>";

      [currencyInput, amountInput, dateInput, categoryInput].forEach(function (i) { setInvalidVisible(i, false); });
      syncValidation();
    }

    function setSavingState(saving) {
      AppUI.showLoader(!!saving);
      AppUI.setModalBusy('createExpenseModal', !!saving);
      AppUI.setBusy(saveBtn, !!saving);
    }

    function open() {
      AppUI.setModalBusy('createExpenseModal', false);
      AppUI.setModalLoading('createExpenseModal', true);
      AppUI.openModal('createExpenseModal');

      if (AppUI.categories && AppUI.categories.ensureLoaded) {
        AppUI.categories.ensureLoaded(function () {
          resetForm();
          AppUI.setModalLoading('createExpenseModal', false);
        });
        return;
      }

      resetForm();
      AppUI.setModalLoading('createExpenseModal', false);
    }

    function close() {
      AppUI.closeModal('createExpenseModal');
    }

    function wireTouched(input) {
      if (!input) return;
      input.addEventListener('input', function () { markTouched(input); syncValidation(); }, true);
      input.addEventListener('blur', function () { markTouched(input); syncValidation(); }, true);
      input.addEventListener('change', function () { markTouched(input); syncValidation(); }, true);
    }

    [currencyInput, amountInput, dateInput, categoryInput].forEach(wireTouched);

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      e.stopPropagation();

      [currencyInput, amountInput, categoryInput, dateInput].forEach(markTouched);

      if (!syncValidation()) return;

      var payload = {
        amount: amountInput.value.trim(),
        category: String(categoryInput.value || '').trim(),
        comments: commentsInput.value.trim(),
        expenseDate: dateInput.value,
        currency: AppUI.currency.normalizeCode(currencyInput.value)
      };

      setSavingState(true);

      google.script.run
        .withSuccessHandler(function (uuid) {
          setSavingState(false);

          if (window.AppSearch && window.AppSearch.upsertFromClient) {
            window.AppSearch.upsertFromClient({
              gmailMessageId: uuid,
              expenseDate: payload.expenseDate,
              amount: payload.amount,
              currency: payload.currency,
              category: payload.category,
              comments: payload.comments,
              source: 'Manual'
            });
          }

          if (window.AppSearch && window.AppSearch.clearPending) {
            window.AppSearch.clearPending(uuid);
          }

          close();
          AppUI.toast('Gasto registrado con éxito.', true);
          resetForm();
        })
        .withFailureHandler(function (err) {
          setSavingState(false);
          var msg = (err && err.message) ? err.message : 'No se pudo guardar.';
          AppUI.toast(msg, false);
        })
        .saveExpense(payload);
    });

    window.AppCreate = { open: open, close: close };

    resetForm();
  });
</script>

```

---

` /src/web/AppUpdate.html`
```
<script>
  document.addEventListener('DOMContentLoaded', function () {
    var AppUI = window.AppUI;
    if (!AppUI) return;
    var $ = AppUI.$;

    var form = $('expense-form');
    if (!form) return;

    var saveBtn = $('saveBtnUpdate');

    var amountInput = $('amountInputUpdate');
    var categoryInput = $('categoryInputUpdate');
    var commentsInput = $('commentsUpdate');
    var gmailInput = $('gmailMessageIdUpdate');
    var currencyInput = $('currencyInputUpdate');

    var subtitleEl = $('updateExpenseModalSubtitle');

    var touched = {};

    function markTouched(input) {
      if (!input || !input.id) return;
      touched[input.id] = true;
    }

    function setInvalidVisible(input, visible) {
      if (!input) return;
      var el = document.querySelector('[data-invalid-for="' + input.id + '"]');
      if (!el) return;
      el.classList.toggle('hidden', !visible);
    }

    function shouldShowInvalid(input) {
      if (!input || !input.id) return false;
      return !!touched[input.id];
    }

    function syncValidation() {
      var inputs = [amountInput, categoryInput];
      inputs.forEach(function (inp) {
        if (!inp) return;
        var show = shouldShowInvalid(inp) && !inp.checkValidity();
        setInvalidVisible(inp, show);
      });
      if (saveBtn) saveBtn.disabled = !form.checkValidity();
      return form.checkValidity();
    }

    function setSavingState(saving) {
      AppUI.showLoader(!!saving);
      AppUI.setModalBusy('updateExpenseModal', !!saving);
      AppUI.setBusy(saveBtn, !!saving);
    }

    function formatModalSubtitle(expenseDate, source) {
      var left = String(expenseDate || '').trim();
      var right = String(source || '').trim();
      if (!left && !right) return '—';
      var leftOut = left;
      var m = left.match(/^(\d{4})-(\d{2})-(\d{2})$/);
      if (m) leftOut = m[3] + '/' + m[2] + '/' + m[1];
      return right ? (leftOut + ' | ' + right) : leftOut;
    }

    function applySubtitle(expenseDate, source) {
      if (!subtitleEl) return;
      var text = formatModalSubtitle(expenseDate, source);
      subtitleEl.textContent = text;
      subtitleEl.title = text;
    }

    function resetTouched() {
      touched = {};
    }

    function fillUpdateFields(data) {
      gmailInput.value = data.gmailMessageId || '';
      amountInput.value = data.amount != null ? String(data.amount) : '';
      commentsInput.value = data.comments || '';

      applySubtitle(data.expenseDate || '', data.source || '');

      if (currencyInput) {
        var code = data.currency ? AppUI.currency.normalizeCode(data.currency) : AppUI.currency.defaultCode();
        currencyInput.value = code;
      }

      if (categoryInput) categoryInput.value = data.category || '';

      resetTouched();
      [amountInput, categoryInput].forEach(function (i) { setInvalidVisible(i, false); });
      syncValidation();
    }

    var originalUpdateData = {
      gmailMessageId: AppUI.initialUpdate.gmailMessageId || '',
      currency: AppUI.initialUpdate.currency || '',
      amount: AppUI.initialUpdate.amount || '',
      expenseDate: AppUI.initialUpdate.expenseDate || '',
      source: AppUI.initialUpdate.source || '',
      comments: AppUI.initialUpdate.comments || '',
      category: AppUI.initialUpdate.category || ''
    };

    function openUpdateModal() { AppUI.setModalBusy('updateExpenseModal', false); AppUI.openModal('updateExpenseModal'); }
    function closeUpdateModal() { AppUI.closeModal('updateExpenseModal'); }

    function openWithItem(item) {
      if (!item || !item.gmailMessageId) {
        AppUI.toast('No se encontró el ID del gasto.', false);
        return;
      }

      originalUpdateData = {
        gmailMessageId: item.gmailMessageId || '',
        amount: item.amount != null ? String(item.amount) : '',
        currency: item.currency || '',
        expenseDate: item.expenseDate || '',
        source: item.source || '',
        comments: item.comments || '',
        category: item.category || ''
      };

      AppUI.setModalLoading('updateExpenseModal', true);
      openUpdateModal();

      if (AppUI.categories && AppUI.categories.ensureLoaded) {
        AppUI.categories.ensureLoaded(function () {
          fillUpdateFields(originalUpdateData);
          AppUI.setModalLoading('updateExpenseModal', false);
        });
        return;
      }

      fillUpdateFields(originalUpdateData);
      AppUI.setModalLoading('updateExpenseModal', false);
    }

    function initForm() {
      if (AppUI.categories && AppUI.categories.ensureLoaded) {
        AppUI.categories.ensureLoaded(function () {
          if (originalUpdateData.gmailMessageId) fillUpdateFields(originalUpdateData);
          else fillUpdateFields({ gmailMessageId: '', amount: '', expenseDate: '', source: '', comments: '', category: '', currency: AppUI.currency.defaultCode() });
        });
        return;
      }

      if (originalUpdateData.gmailMessageId) fillUpdateFields(originalUpdateData);
      else fillUpdateFields({ gmailMessageId: '', amount: '', expenseDate: '', source: '', comments: '', category: '', currency: AppUI.currency.defaultCode() });
    }

    function wireTouched(input) {
      if (!input) return;
      input.addEventListener('input', function () { markTouched(input); syncValidation(); }, true);
      input.addEventListener('blur', function () { markTouched(input); syncValidation(); }, true);
      input.addEventListener('change', function () { markTouched(input); syncValidation(); }, true);
    }

    [amountInput, categoryInput].forEach(wireTouched);

    initForm();

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      e.stopPropagation();

      [amountInput, categoryInput].forEach(markTouched);

      if (!syncValidation()) return;

      var payload = {
        gmailMessageId: gmailInput.value,
        category: String(categoryInput.value || '').trim(),
        comments: commentsInput.value.trim(),
        amount: amountInput.value.trim(),
        currency: AppUI.currency.normalizeCode(currencyInput.value)
      };

      if (!payload.gmailMessageId) {
        AppUI.toast('No hay un ID de gasto para actualizar.', false);
        return;
      }

      var updatedForGrid = {
        gmailMessageId: payload.gmailMessageId,
        amount: payload.amount || originalUpdateData.amount,
        currency: payload.currency,
        currencySymbol: AppUI.currency.symbol(payload.currency),
        category: payload.category,
        comments: payload.comments,
        expenseDate: originalUpdateData.expenseDate,
        source: originalUpdateData.source
      };

      if (window.AppSearch && window.AppSearch.upsertFromClient) window.AppSearch.upsertFromClient(updatedForGrid);

      setSavingState(true);

      google.script.run
        .withSuccessHandler(function () {
          setSavingState(false);

          if (window.AppSearch && window.AppSearch.clearPending) window.AppSearch.clearPending(payload.gmailMessageId);
          if (window.AppSearch && window.AppSearch.refreshFromBackend) window.AppSearch.refreshFromBackend();

          AppUI.toast('Gasto actualizado con éxito.', true);
          closeUpdateModal();
        })
        .withFailureHandler(function (err) {
          setSavingState(false);

          if (window.AppSearch && window.AppSearch.upsertFromClient) {
            window.AppSearch.upsertFromClient(originalUpdateData);
            if (window.AppSearch.clearPending) window.AppSearch.clearPending(payload.gmailMessageId);
          }

          var msg = (err && err.message) ? err.message : 'No se pudo actualizar.';
          AppUI.toast(msg, false);
        })
        .updateExpense(payload);
    });

    window.AppUpdate = {
      openWithItem: openWithItem,
      close: closeUpdateModal
    };

    syncValidation();
  });
</script>

```

---

` /src/web/ToastsAndModals.html`
```
<!-- Status modal (Flowbite) -->
<div id="statusModal" tabindex="-1" aria-hidden="true"
     class="hidden fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden p-4">
  <div class="relative w-full max-w-sm">
    <div class="relative rounded-2xl bg-white shadow-lg dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
      <div class="p-6 text-center">
        <div class="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-full bg-gray-50 text-gray-800 dark:bg-gray-950 dark:text-gray-200 border border-gray-200 dark:border-gray-800">
          <i id="statusModalIcon" class="fa-solid fa-circle-check text-2xl"></i>
        </div>
        <div id="statusModalMessage" class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">—</div>
      </div>
    </div>
  </div>
</div>

<!-- Create modal -->
<div id="createExpenseModal" tabindex="-1" aria-hidden="true"
     class="hidden fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden p-4">
  <div class="relative w-full max-w-3xl">
    <div class="relative rounded-2xl bg-white shadow-lg dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
      <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-gray-800">
        <div class="flex items-center gap-2">
          <div class="flex h-9 w-9 items-center justify-center rounded-xl border border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-200">
            <i class="fa-solid fa-plus"></i>
          </div>
          <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100">Nuevo gasto</h3>
        </div>
        <button type="button"
                class="inline-flex items-center justify-center rounded-lg p-2 text-gray-500 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-gray-800 dark:hover:text-white"
                data-close-modal="createExpenseModal"
                aria-label="Cerrar">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
      <div class="p-5">
        <div data-modal-loader="true" class="hidden flex items-center justify-center py-10">
          <div role="status" class="h-10 w-10 animate-spin rounded-full border-4 border-gray-200 border-t-gray-700 dark:border-gray-700 dark:border-t-gray-200"></div>
          <span class="sr-only">Cargando...</span>
        </div>
        <div data-modal-content="true">
          <?!= include('ViewSave', { defaultDate: defaultDate, currencies: currencies, categories: categories }); ?>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Update modal -->
<div id="updateExpenseModal" tabindex="-1" aria-hidden="true"
     class="hidden fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden p-4">
  <div class="relative w-full max-w-3xl">
    <div class="relative rounded-2xl bg-white shadow-lg dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
      <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-gray-800">
        <div class="flex items-center gap-2">
          <div class="flex h-9 w-9 items-center justify-center rounded-xl border border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-200">
            <i class="fa-solid fa-pen-to-square"></i>
          </div>
          <div class="min-w-0">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100">Editar gasto</h3>
            <div id="updateExpenseModalSubtitle" class="mt-0.5 truncate text-xs font-semibold text-gray-500 dark:text-gray-400" title="">—</div>
          </div>
        </div>
        <button type="button"
                class="inline-flex items-center justify-center rounded-lg p-2 text-gray-500 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-gray-800 dark:hover:text-white"
                data-close-modal="updateExpenseModal"
                aria-label="Cerrar">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
      <div class="p-5">
        <div data-modal-loader="true" class="hidden flex items-center justify-center py-10">
          <div role="status" class="h-10 w-10 animate-spin rounded-full border-4 border-gray-200 border-t-gray-700 dark:border-gray-700 dark:border-t-gray-200"></div>
          <span class="sr-only">Cargando...</span>
        </div>
        <div data-modal-content="true">
          <?!= include('ViewUpdate', { currencies: currencies, categories: categories }); ?>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Config modal -->
<div id="configModal" tabindex="-1" aria-hidden="true"
     class="hidden fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden p-4">
  <div class="relative w-full max-w-3xl">
    <div class="relative rounded-2xl bg-white shadow-lg dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
      <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-gray-800">
        <div class="flex items-center gap-2">
          <div class="flex h-9 w-9 items-center justify-center rounded-xl border border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-200">
            <i class="fa-solid fa-gear"></i>
          </div>
          <div>
            <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100">Configuración</h3>
          </div>
        </div>
        <button type="button"
                class="inline-flex items-center justify-center rounded-lg p-2 text-gray-500 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-gray-800 dark:hover:text-white"
                data-close-modal="configModal"
                aria-label="Cerrar">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>

      <div class="p-5">
        <div data-modal-loader="true" class="hidden flex items-center justify-center py-10">
          <div role="status" class="h-10 w-10 animate-spin rounded-full border-4 border-gray-200 border-t-gray-700 dark:border-gray-700 dark:border-t-gray-200"></div>
          <span class="sr-only">Cargando...</span>
        </div>

        <div data-modal-content="true" class="space-y-3">
          <!-- Section: Categories (collapsible) -->
          <div class="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 overflow-hidden">
            <button id="configToggleCategories" type="button" aria-expanded="false"
                    class="w-full flex items-center justify-between gap-3 px-4 py-3 text-left hover:bg-gray-50 dark:hover:bg-gray-950">
              <div class="flex items-center gap-3">
                <div class="flex h-9 w-9 items-center justify-center rounded-xl border border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-200">
                  <i class="fa-solid fa-tags"></i>
                </div>
                <div class="min-w-0">
                  <div class="flex items-center gap-2">
                    <div class="text-sm font-semibold text-gray-900 dark:text-gray-100">Categorías de gasto</div>
                    <span id="categoriesCountBadge" class="hidden inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-semibold text-gray-700 dark:bg-gray-800 dark:text-gray-100">
                      <span id="categoriesCountBadgeText">0</span>
                    </span>
                  </div>
                <div class="text-xs text-gray-500 dark:text-gray-400">Establece un límite mensual para tus categorías de gasto</div>
                </div>
              </div>

              <div class="flex items-center gap-2">
                <i id="configChevronCategories" class="fa-solid fa-chevron-down text-xs text-gray-500 dark:text-gray-400 transition-transform"></i>
              </div>
            </button>

            <div id="configSectionCategories" class="hidden border-t border-gray-200 dark:border-gray-800">
              <div class="p-4 space-y-3">
                <div id="categoriesRows" class="max-h-80 overflow-y-auto space-y-1"></div>

                <div id="categoriesError" class="hidden rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-950/40 dark:text-red-200"></div>

                <div class="flex items-center justify-end gap-2">
                  <button id="saveCategoriesBtn" type="button" disabled
                          class="inline-flex items-center gap-2 rounded-xl bg-gray-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-white dark:text-gray-900 dark:hover:bg-gray-200">
                    <i class="fa-solid fa-floppy-disk"></i> Guardar
                  </button>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
</div>

```

---

` /src/web/ViewSave.html`
```
<form id="new-expense-form" class="space-y-4" novalidate>
  <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
    <div class="md:col-span-3">
      <label for="currencyInputSave" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Moneda <span class="text-red-500">*</span></label>
      <select id="currencyInputSave" name="currency"
              class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100"
              required>
        <? for (var i = 0; i < (currencies || []).length; i++) { var c = currencies[i]; ?>
          <option value="<?= c.code ?>" <?=(i===0) ? 'selected' : '' ?>><?= c.code ?> (<?= c.symbol ?>)</option>
        <? } ?>
      </select>
      <p class="mt-1 hidden text-xs text-red-500" data-invalid-for="currencyInputSave">Seleccione una moneda.</p>
    </div>

    <div class="md:col-span-3">
      <label for="amountInputSave" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Importe <span class="text-red-500">*</span></label>
      <input id="amountInputSave" name="amount"
             class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100"
             inputmode="decimal" autocomplete="off" placeholder="Ej: 125.50" required pattern="^\d+(\.\d+)?$" data-positive-decimal="true" />
      <p class="mt-1 hidden text-xs text-red-500" data-invalid-for="amountInputSave">Ingrese un número positivo</p>
    </div>

    <div class="md:col-span-3">
      <label for="dateInputSave" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Fecha <span class="text-red-500">*</span></label>
      <input id="dateInputSave" name="expenseDate" type="date"
             class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100"
             value="<?= defaultDate ?>" required />
      <p class="mt-1 hidden text-xs text-red-500" data-invalid-for="dateInputSave">Seleccione una fecha válida.</p>
    </div>

    <div class="md:col-span-3">
      <label for="categoryInputSave" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Categoría <span class="text-red-500">*</span></label>
      <select id="categoryInputSave" name="category" data-category-select="true" data-category-placeholder="true"
              class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100"
              required>
        <option value="" disabled selected>Seleccione</option>
        <? for (var i = 0; i < (categories || []).length; i++) { var c = categories[i]; ?>
          <option value="<?= c.description ?>"><?= c.description ?></option>
        <? } ?>
      </select>
      <p class="mt-1 hidden text-xs text-red-500" data-invalid-for="categoryInputSave">Seleccione una categoría.</p>
    </div>

    <div class="md:col-span-12">
      <label for="commentsSave" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Comentarios</label>
      <input id="commentsSave" name="comments" autocomplete="off" placeholder="Opcional"
             class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100" />
    </div>

    <div class="md:col-span-12 flex flex-wrap gap-2">
      <button id="saveBtn" type="submit"
              class="inline-flex items-center gap-2 rounded-xl bg-gray-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-white dark:text-gray-900 dark:hover:bg-gray-200">
        <i class="fa-solid fa-floppy-disk"></i> Guardar
      </button>
    </div>
  </div>
</form>

```

---

` /src/web/ViewUpdate.html`
```
<form id="expense-form" class="space-y-4" novalidate>
  <input id="gmailMessageIdUpdate" type="hidden" />

  <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
    <div class="md:col-span-3">
      <label for="currencyInputUpdate" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Moneda</label>
      <select id="currencyInputUpdate"
              class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-100">
        <? for (var i = 0; i < (currencies || []).length; i++) { var c = currencies[i]; ?>
          <option value="<?= c.code ?>" <?=(i===0) ? 'selected' : '' ?>><?= c.code ?> (<?= c.symbol ?>)</option>
        <? } ?>
      </select>
    </div>

    <div class="md:col-span-3">
      <label for="amountInputUpdate" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Importe <span class="text-red-500">*</span></label>
      <input id="amountInputUpdate" inputmode="decimal" placeholder="Ej: 125.50" autocomplete="off" required pattern="^\d+(\.\d+)?$" data-positive-decimal="true"
             class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-100" />
      <p class="mt-1 hidden text-xs text-red-500" data-invalid-for="amountInputUpdate">Ingrese un número positivo</p>
    </div>

    <div class="md:col-span-3">
      <label for="categoryInputUpdate" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Categoría <span class="text-red-500">*</span></label>
      <select id="categoryInputUpdate" data-category-select="true" data-category-placeholder="true" required
              class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-100">
        <option value="" disabled selected>Seleccione</option>
        <? for (var i = 0; i < (categories || []).length; i++) { var c = categories[i]; ?>
          <option value="<?= c.description ?>"><?= c.description ?></option>
        <? } ?>
      </select>
      <p class="mt-1 hidden text-xs text-red-500" data-invalid-for="categoryInputUpdate">Seleccione una categoría.</p>
    </div>

    <div class="md:col-span-3">
      <label for="commentsUpdate" class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">Comentarios</label>
      <input id="commentsUpdate" autocomplete="off" placeholder="Opcional"
             class="block w-full rounded-xl border border-gray-200 bg-white p-2.5 text-sm text-gray-900 focus:border-gray-400 focus:ring-0 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-100" />
    </div>

    <div class="md:col-span-12 flex flex-wrap gap-2">
      <button id="saveBtnUpdate" type="submit"
              class="inline-flex items-center gap-2 rounded-xl bg-gray-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-white dark:text-gray-900 dark:hover:bg-gray-200">
        <i class="fa-solid fa-floppy-disk"></i> Guardar
      </button>
    </div>
  </div>
</form>

```

---

` /src/main.gs`
```
/** @OnlyCurrentDoc */

// fill out expenses
function fillExpensesAndNotify() {
  App.ExpenseFillerService.fillExpensesAndNotify();
}

function createTrigger() {
  App.Trigger.createTrigger('fillExpensesAndNotify');
}

// view
function doGet(e) {
  return App.ExpenseView.doGet(e);
}

function include(filename, data) {
  var t = HtmlService.createTemplateFromFile(filename);
  if (data) {
    for (var key in data) {
      if (data.hasOwnProperty(key)) {
        t[key] = data[key];
      }
    }
  }

  return t.evaluate().getContent();
}

// services consumed by view
function updateExpense(payload) {
  return App.ExpenseUpdateService.updateExpense(payload);
}

function saveExpense(payload) {
  return App.ExpenseSaveService.saveExpense(payload);
}

function findExpensesByFilters(filters) {
  return App.ExpenseSearchService.findExpensesByFilters(filters);
}

function deleteExpense(payload) {
  return App.ExpenseDeleteService.deleteExpense(payload);
}

function getCurrencies() {
  return App.CurrencyService.getCurrencies();
}

function getCategories() {
  return App.ExpenseCategoryService.getCategories();
}

function replaceCategories(payload) {
  App.ExpenseCategoryService.replaceCategories(payload);
}
```

---

` /src/main/index.ts`
```
export {default as Trigger} from './commons/trigger/Trigger';
export {default as ExpenseView} from './commons/view/ExpenseView';
export {default as ExpenseFillerService} from './entrypoint/proof-of-payment/service/ExpenseFillerService';
export {default as ExpenseSaveService} from './entrypoint/expenses/service/ExpenseSaveService';
export {default as ExpenseUpdateService} from './entrypoint/expenses/service/ExpenseUpdateService';
export {default as ExpenseSearchService} from './entrypoint/expenses/service/ExpenseSearchService';
export {default as ExpenseDeleteService} from './entrypoint/expenses/service/ExpenseDeleteService';
export {default as CurrencyService} from './entrypoint/catalogs/service/CurrencyService';
export {default as ExpenseCategoryService} from './entrypoint/expenses/service/ExpenseCategoryService';
```

---

` /src/main/commons/view/ExpenseView.ts`
```
/// <reference types="google-apps-script" />
import { Properties } from '../properties/Properties';
import { DateConstants } from '../constants/DateConstants';
import { Props } from '../constants/Props';
import { Strings } from '../constants/Strings';
import { WebActions } from '../constants/WebAction';
import { TimeUtil } from '../utils/TimeUtil';
import CurrencyService from '../../entrypoint/catalogs/service/CurrencyService';
import ExpenseCategoryService from '../../entrypoint/expenses/service/ExpenseCategoryService';

const ExpenseView = (() => {

  function doGet(e: GoogleAppsScript.Events.DoGet): GoogleAppsScript.HTML.HtmlOutput {
    const params = (e && e.parameter) || ({} as Record<string, string>);
    const action = params.action || WebActions.SEARCH;

    const tpl = HtmlService.createTemplateFromFile('Index');
    tpl.defaultDate = Utilities.formatDate(new Date(), DateConstants.TIME_ZONE, 'yyyy-MM-dd');
    tpl.initialTab = action;
    tpl.currencies = CurrencyService.getCurrencies();
    tpl.categories = ExpenseCategoryService.getCategories();

    tpl.gmailMessageId = params.gmailMessageId || Strings.EMPTY;
    tpl.amount = params.amount || Strings.EMPTY;
    tpl.currency = params.currency || Strings.EMPTY;
    tpl.expenseDate = params.expenseDate || Strings.EMPTY;
    tpl.source = params.source || Strings.EMPTY;
    tpl.kind = params.kind || Strings.EMPTY;
    tpl.comments = params.comments || Strings.EMPTY;
    tpl.category = params.category || Strings.EMPTY;
    tpl.lastCheckDate = TimeUtil.fromUtcToTimeZoneStr(Properties.get(Props.LAST_CHECK_DATE));

    const output = tpl
      .evaluate()
      .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL)
      .setSandboxMode(HtmlService.SandboxMode.IFRAME)
      .setTitle('Gestión de gastos');

    output.addMetaTag('viewport', 'width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover');
    return output;
  }

  return { doGet };
})();

export default ExpenseView;
```

---

` /src/main/entrypoint/expenses/dto/response/ExpenseUpdateResponseDto.ts`
```
export class ExpenseUpdateResponseDto {

  constructor(
    public isUpdated: boolean,
    public isBelowLimit: boolean,
  ) { }
}

```

---

` /src/main/entrypoint/expenses/service/ExpenseUpdateService.ts`
```
import { ExpenseEntity } from "../repository/entity/ExpenseEntity";
import { ExpenseRepository } from "../repository/ExpenseRepository";
import { TimeUtil } from "../../../commons/utils/TimeUtil";
import ExpenseLimitValidator from "../helper/ExpenseLimitValidator";
import { ExpenseUpdateResponseDto } from "../dto/response/ExpenseUpdateResponseDto";

const ExpenseUpdateService = (() => {

    function updateExpense(payload: {
        gmailMessageId: string;
        category: string;
        comments?: string;
        currency?: string;
        amount?: string;
    }): ExpenseUpdateResponseDto {

        const expenseAmount = Number(String(payload.amount).trim());
        const isBelowLimit = ExpenseLimitValidator.validateIfExistingExpenseIsBelowLimit(payload.gmailMessageId, payload.category, expenseAmount);

        const expense = new ExpenseEntity(payload.gmailMessageId);
        expense.isBelowLimit = isBelowLimit;
        expense.category = String(payload.category).trim();
        expense.amount = expenseAmount;
        expense.currency = String(payload.currency).trim();
        expense.comments = String(payload.comments).trim();
        expense.checkedAt = TimeUtil.nowUtc();

        const isUpdated = ExpenseRepository.updateByGmailMessageId(expense);
        
        return new ExpenseUpdateResponseDto(isUpdated, isBelowLimit);
    }

    return { updateExpense };
})();

export default ExpenseUpdateService;
```

---

` /src/main/entrypoint/expenses/dto/response/ExpenseSaveResponseDto.ts`
```
export class ExpenseSaveResponseDto {

  constructor(
    public gmailMessageId: string,
    public isBelowLimit: boolean,
  ) { }
}

```

---

` /src/main/entrypoint/expenses/service/ExpenseSaveService.ts`
```
import { ExpenseEntity } from "../repository/entity/ExpenseEntity";
import { ExpenseRepository } from "../repository/ExpenseRepository";
import { AppConstants } from "../../../commons/constants/AppConstants";
import { TimeUtil } from "../../../commons/utils/TimeUtil";
import ExpenseLimitValidator from "../helper/ExpenseLimitValidator";
import { ExpenseSaveRequestDto } from "../dto/request/ExpenseSaveRequestDto";
import { ExpenseSaveResponseDto } from "../dto/response/ExpenseSaveResponseDto";

const ExpenseSaveService = (() => {

    function saveExpense(saveRequest: ExpenseSaveRequestDto): ExpenseSaveResponseDto {
        const expenseAmount = Number(String(saveRequest.amount).trim());
        const isBelowLimit = ExpenseLimitValidator.validateIfNewExpenseIsBelowLimit(saveRequest.category.trim(), expenseAmount);

        const expense = new ExpenseEntity(
            Utilities.getUuid(),
            TimeUtil.nowUtc(),
            TimeUtil.fromYyyyMmDdToUtcStr(saveRequest.expenseDate),
            isBelowLimit,
            String(saveRequest.category).trim(),
            AppConstants.MANUALLY,
            saveRequest.currency,
            expenseAmount,
            String(saveRequest.comments).trim()
        );

        const createdId = ExpenseRepository.insert(expense);
        if (!createdId) 
            throw new Error('[ExpenseSaveService] Record could not be saved.');

        ExpenseRepository.sortByExpenseDateDesc();
        
        return new ExpenseSaveResponseDto(createdId, isBelowLimit);
    }

    return { saveExpense };
})();

export default ExpenseSaveService;
```

---

