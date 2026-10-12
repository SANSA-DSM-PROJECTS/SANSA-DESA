const keycloak = new Keycloak({
  url: "http://localhost:8080",
  realm: "desa",
  clientId: "desa-portal"
});

// Initialize Keycloak
keycloak.init({
  onLoad: "check-sso",
  pkceMethod: "S256"
}).then(authenticated => {

  console.log("Authenticated:", authenticated);

  // Update UI
  const loginBtn = document.querySelector("#loginBtn");
  const logoutBtn = document.querySelector("#logoutBtn");
  const userDisplay = document.querySelector("#userDisplay");

  if (authenticated) {

    if (loginBtn) loginBtn.style.display = "none";
    if (logoutBtn) logoutBtn.style.display = "inline-flex";

    if (userDisplay) {
      userDisplay.innerHTML =
        `👤 ${keycloak.tokenParsed.preferred_username}`;
    }

    console.log(keycloak.tokenParsed);

  } else {

    if (loginBtn) loginBtn.style.display = "inline-flex";
    if (logoutBtn) logoutBtn.style.display = "none";

  }

}).catch(err => {
  console.error("Keycloak init failed", err);
});

// Login
function login() {
  keycloak.login();
}

// Logout
function logout() {
  keycloak.logout({
    redirectUri: window.location.origin + "/desa/"
  });
}