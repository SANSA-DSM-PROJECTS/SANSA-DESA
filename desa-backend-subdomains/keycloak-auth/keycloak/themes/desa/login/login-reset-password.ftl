<#import "template.ftl" as layout>

<@layout.registrationLayout displayInfo=false displayMessage=!messagesPerField.existsError('username'); section>

<#if section == "title">
    Dlula Reset Password

<#elseif section == "header">
    <!-- Optional header -->

<#elseif section == "form">

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title> Reset Password | Dlula</title> 
    
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="login-pf d-flex flex-column min-vh-100">

<div class="container flex-grow-1 d-flex align-items-center">
    <div class="row justify-content-center w-100">
        <div class="col-md-5 col-lg-4">

            <div class="card shadows rounded-4">
                <div class="card-body p-4">

                    <div class="text-center mb-4">
                        <img src="${url.resourcesPath}/img/desa-logo.png"
                             class="img-fluid mb-3"
                             style="max-height: 120px;">
                        <h4 class="fw-bold">Forgot Password</h4>
                    </div>

                    <#if message?has_content>
                        <#-- Keycloak message types: success, warning, error, info -->
                        <#assign alertType = (message.type == "error")?then("danger", message.type)>
                        <div class="alert alert-${alertType} py-2" role="alert">
                            ${kcSanitize(message.summary)?no_esc}
                        </div>
                    </#if>

                    <form id="kc-reset-password-form" action="${url.loginAction}" method="post">
                        <!-- Username / Email Field -->
                        <div class="mb-3">
                            <label for="username" class="form-label fw-semibold">
                                <#if !realm.loginWithEmailAllowed>
                                    Username
                                <#elseif !realm.registrationEmailAsUsername>
                                    Username / Email Address
                                <#else>
                                    Email Address
                                </#if>
                            </label>
                            <input type="text" 
                           		id="username" name="username" class="form-control <#if messagesPerField.existsError('username')>is-invalid</#if>"
                               	value="${(auth.attemptedUsername!'')}" placeholder="Enter your username or email" autofocus aria-invalid="<#if messagesPerField.existsError('username')>true</#if>"/>
                            <#if messagesPerField.existsError('username')>
                            	<div class="invalid-feedback d-block mt-2">
                                	${kcSanitize(messagesPerField.get('username'))?no_esc}
                                </div>
                            </#if>
                        </div>

                        <div class="d-grid gap-3 mt-3">
                            <button type="submit" class="btn btn-primary btn-lg">
                                Submit
                            </button>
                            <div class="text-center backto small mt-3">
                                <a href="${url.loginUrl}" class="text-decoration-none">
		                            			← Back to login
		                        </a>
                            </div>
                        </div>
                    </form>

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
<script>
    document.title = "Dlula Reset Password";
    document.addEventListener('DOMContentLoaded', function() {
        const otherTitles = document.querySelectorAll('.kc-page-title, #kc-page-title');
        otherTitles.forEach(title => title.remove());
    });
</script>
</body>
</html>

<#elseif section == "info">
<div class="container mt-3">
    <div class="row justify-content-center">
        <div class="col-md-6 col-lg-5">
            <div class="alert alert-info text-center">
                <#if realm.duplicateEmailsAllowed>
                    ${msg("emailInstructionUsername")}
                <#else>
                    ${msg("emailInstruction")}
                </#if>
            </div>
        </div>
    </div>
</div>
</#if>

</@layout.registrationLayout>

