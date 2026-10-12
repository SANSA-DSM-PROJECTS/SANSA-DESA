<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dlula Login</title>
	
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">
    
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex flex-column min-vh-100">

<div class="container flex-grow-1 d-flex align-items-center">
    <div class="row justify-content-center w-100">
        <div class="col-md-5 col-lg-4">

            <div class="card shadows rounded-4">
                <div class="card-body p-4">

                    <div class="text-center mb-4">
                        <img src="${url.resourcesPath}/img/desa-logo.png" alt="DESA" class="img-fluid mb-3" style="max-height: 120px;">
                        <h4 class="fw-bold">
							<#if client.name?? && client.name?has_content>
							${kcSanitize(advancedMsg(client.name))?no_esc}
							<#else>
							${client.clientId}
							</#if>
						</h4>
                    </div>

                    <#if message?has_content>
                        <#-- Keycloak message types: success, warning, error, info -->
                        <#assign alertType = (message.type == "error")?then("danger", message.type)>
                        <div class="alert alert-${alertType} py-2" role="alert">
                            ${kcSanitize(message.summary)?no_esc}
                        </div>
                    </#if>

                    <form id="kc-form-login" action="${url.loginAction}" method="post">
                        <div class="mb-3">
                            <label for="username" class="form-label">
                                <#if realm.registrationEmailAsUsername>Email<#elseif realm.loginWithEmailAllowed>Username or email<#else>Username</#if>
                            </label>
                            <input id="username" class="form-control" type="text" name="username"
                                   value="${(login.username!'')}" autocomplete="username" autofocus required>
                        </div>

                        <div class="mb-3">
                            <label for="password" class="form-label">Password</label>
                            <input id="password" class="form-control" type="password" name="password"
                                   autocomplete="current-password" required>
                        </div>

                        <#if realm.rememberMe>
                            <div class="form-check mb-3 small">
                                <input class="form-check-input" type="checkbox" id="rememberMe" name="rememberMe"
                                       <#if login.rememberMe??>checked</#if>>
                                <label class="form-check-label fw-normal" for="rememberMe">Remember me</label>
                            </div>
                        </#if>

                        <div class="d-grid">
                            <button id="kc-login" class="btn btn-primary btn-lg" type="submit">
                                Sign in
                            </button>
                        </div>
                        
                        <div class="d-flex realmaction justify-content-between small mt-2">

                            <#if realm.resetPasswordAllowed>
                                <a href="${url.loginResetCredentialsUrl}">
                                    Forgot password?
                                </a>
                            </#if>

                            <#if realm.registrationAllowed>
                                <a href="${url.registrationUrl}">
                                    New user?&nbsp;Register
                                </a>
                            </#if>

                        </div>
                    </form>
                    <script>
                        // Prevent double submission while Keycloak processes the login
                        document.getElementById("kc-form-login").addEventListener("submit", function () {
                            var btn = document.getElementById("kc-login");
                            btn.disabled = true;
                            btn.textContent = "Signing in...";
                        });
                    </script>
                    
                    <#if social?? && social.providers?? && social.providers?has_content>
						<div class="signin mt-4 text-center mb-4">
							<hr />
							<h6 class="fw-bold mb-3">Or sign in with</h6>

							<div class="row g-3 justify-content-center">
								<#list social.providers as p>
									<div class="col-12 col-md-6">
										<a href="${p.loginUrl}"
										   class="btn social-btn d-flex align-items-center justify-content-center
											  <#if p.alias == 'google'>google</#if>
											  <#if p.alias == 'facebook'>facebook</#if>">

											<#if p.alias == "google">
											<i class="bi bi-google me-2"></i>
											<span>Google</span>

											<#elseif p.alias == "facebook">
											<i class="bi bi-facebook me-2"></i>
											<span>Facebook</span>

											<#else>
											<span>Sign in with ${p.displayName}</span>
											</#if>
										</a>
									</div>
								</#list>
							</div>
						</div>
					</#if>

                </div>
            </div>

        </div>
    </div>
</div>

<footer class="site-footer">
    <div class="site-footer-inner">
        <img src="${url.resourcesPath}/img/dsti-footer.jpg" alt="Department of Science, Technology and Innovation" class="site-footer-logo site-footer-logo--sti">
        <p class="site-footer-copyright">Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.</p>
        <img src="${url.resourcesPath}/img/sansa-footer.png" alt="SANSA" class="site-footer-logo">
    </div>
</footer>

<script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>
</body>
</html>

