(function () {
  "use strict";

  const MOD_ID = "justbid-mobile-mod";
  const INLINE_BADGE_CLASS = "justbid-inline-total";
  const DEFAULTS = {
    buyersPremiumRate: 0.15,
    lotFee: 2,
    taxRate: 0.087,
  };

  function parseMoney(value) {
    if (!value) return null;
    const match = String(value).replace(/,/g, "").match(/\$?\s*([0-9]+(?:\.[0-9]{1,2})?)/);
    return match ? Number(match[1]) : null;
  }

  function formatMoney(value) {
    return new Intl.NumberFormat("en-US", {
      currency: "USD",
      style: "currency",
    }).format(value);
  }

  function calculateTotal(basePrice, options) {
    const settings = { ...DEFAULTS, ...options };
    const premium = basePrice * settings.buyersPremiumRate;
    const taxableSubtotal = basePrice + premium + settings.lotFee;
    const tax = taxableSubtotal * settings.taxRate;

    return {
      basePrice,
      premium,
      lotFee: settings.lotFee,
      tax,
      total: taxableSubtotal + tax,
    };
  }

  function findCurrentBid() {
    const selectors = [
      "[data-ui--current-bid]",
      "[data-ui--bid-amount]",
      "[data-current-bid]",
      ".current-bid-price",
      ".current-bid",
      ".bid-amount",
    ];

    for (const selector of selectors) {
      const element = document.querySelector(selector);
      const value = parseMoney(element && element.textContent);
      if (value !== null) return value;
    }

    const labels = Array.from(document.querySelectorAll("body *"))
      .filter((element) => /current bid|high bid|winning bid/i.test(element.textContent || ""))
      .slice(0, 20);

    for (const label of labels) {
      const value = parseMoney(label.textContent);
      if (value !== null) return value;
    }

    return null;
  }

  function renderCalculator() {
    const bid = findCurrentBid();
    const existing = document.getElementById(MOD_ID);

    if (bid === null) {
      if (existing) existing.remove();
      return;
    }

    const estimate = calculateTotal(bid);
    const panel = existing || document.createElement("aside");
    panel.id = MOD_ID;
    panel.innerHTML = `
      <strong>Estimated total</strong>
      <span>${formatMoney(estimate.total)}</span>
      <small>${formatMoney(estimate.basePrice)} bid + ${formatMoney(estimate.premium)} premium + ${formatMoney(estimate.lotFee)} lot fee + ${formatMoney(estimate.tax)} tax</small>
    `;

    if (!existing) document.body.appendChild(panel);
  }

  function findAuctionPriceNodes() {
    const selectors = [
      ".current-bid-price",
      "[data-ui--current-bid]",
      "[data-ui--bid-amount]",
      "[data-current-bid]",
      ".current-bid",
      ".bid-amount",
    ];

    return Array.from(document.querySelectorAll(selectors.join(",")))
      .filter((element) => element instanceof HTMLElement);
  }

  function renderInlineAuctionTotals() {
    for (const element of findAuctionPriceNodes()) {
      if (element.dataset.justBidModded === "true") continue;

      const bid = parseMoney(element.textContent);
      if (bid === null) continue;

      const estimate = calculateTotal(bid);
      const badge = document.createElement("div");
      badge.className = INLINE_BADGE_CLASS;
      badge.textContent = `Est. total: ${formatMoney(estimate.total)}`;

      element.insertAdjacentElement("afterend", badge);
      element.dataset.justBidModded = "true";
    }
  }

  function refreshMod() {
    renderCalculator();
    renderInlineAuctionTotals();
  }

  function injectStyles() {
    if (document.getElementById(`${MOD_ID}-style`)) return;

    const style = document.createElement("style");
    style.id = `${MOD_ID}-style`;
    style.textContent = `
      #${MOD_ID} {
        position: fixed;
        left: 12px;
        right: 12px;
        bottom: max(12px, env(safe-area-inset-bottom));
        z-index: 2147483647;
        display: grid;
        gap: 4px;
        padding: 12px;
        border: 1px solid rgba(15, 23, 42, 0.14);
        border-radius: 8px;
        background: rgba(255, 255, 255, 0.96);
        box-shadow: 0 10px 30px rgba(15, 23, 42, 0.2);
        color: #0f172a;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        line-height: 1.25;
      }
      #${MOD_ID} strong { font-size: 13px; text-transform: uppercase; }
      #${MOD_ID} span { font-size: 22px; font-weight: 800; }
      #${MOD_ID} small { color: #475569; font-size: 12px; }
      .${INLINE_BADGE_CLASS} {
        color: #15803d;
        font-size: 0.82em;
        font-weight: 700;
        line-height: 1.25;
        margin-top: 2px;
      }
    `;
    document.head.appendChild(style);
  }

  function start() {
    injectStyles();
    refreshMod();

    const observer = new MutationObserver(() => {
      window.clearTimeout(window.__justBidModTimer);
      window.__justBidModTimer = window.setTimeout(refreshMod, 250);
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
      characterData: true,
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }

  window.JustBidMod = {
    calculateTotal,
    refresh: refreshMod,
  };
})();
