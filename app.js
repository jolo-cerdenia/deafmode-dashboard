const SIGNAL_URL = "signal.json";
const WAKEFULNESS_URL = "wakefulness.json";

async function loadDashboard() {

  await Promise.all([
    loadSignal(),
    loadWakefulness()
  ]);
}

async function loadSignal() {

  try {

    const response =
      await fetch(`${SIGNAL_URL}?t=${Date.now()}`);

    const data =
      await response.json();

    renderSignal(data);

  } catch (error) {

    console.error(error);

    document.getElementById("signal").textContent =
      "UNKNOWN";
  }
}

async function loadWakefulness() {

  try {

    const response =
      await fetch(`${WAKEFULNESS_URL}?t=${Date.now()}`);

    const data =
      await response.json();

    renderWakefulness(data);

  } catch (error) {

    console.error(error);

    document.getElementById("wakefulness").textContent =
      "UNKNOWN";
  }
}

function renderSignal(data) {

  document.getElementById("signal").textContent =
    data.signal || "UNKNOWN";

  document.getElementById("inference").textContent =
    data.inference || "awaiting inference";

  document.getElementById("drift").textContent =
    data.drift || "no active drift";

  document.getElementById("response").textContent =
    data.response || "maintain operational stability";

  document.getElementById("timestamp").textContent =
    `last update ${data.generated_at || "unknown"}`;
}

function renderWakefulness(data) {

  const lastSeen =
    new Date(data.last_seen);

  const now =
    new Date();

  const diffMinutes =
    (now - lastSeen) / 1000 / 60;

  const state =
    diffMinutes <= 20
      ? "AWAKE"
      : "ASLEEP";

  document.getElementById("wakefulness").textContent =
    state;
}

loadDashboard();

setInterval(loadDashboard, 60000);
