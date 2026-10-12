<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta name="viewport" content="width=device-width, initial-scale=1">
	
    <title> Update Password | Dlula</title>
	
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex align-items-center min-vh-100">

<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5 col-lg-4">

            <div class="card shadows rounded-4">
                <div class="card-body p-4">

                    <div class="text-center mb-4">
                        <img
                            src="${url.resourcesPath}/img/SANSA.jpg"
                            alt="Dlula"
                            class="img-fluid mb-3"
                            style="max-height: 80px;"
                        >

                        <h4 class="fw-bold">
                            Update Password
                        </h4>

                        <p class="text-muted small mb-0">
                            Enter and confirm your new password.
                        </p>
                    </div>

                    <#if message?? && message?has_content>
                        <div
                            class="alert text-center py-2
                            <#if message.type == 'success'>
                                alert-success
                            <#elseif message.type == 'warning'>
                                alert-warning
                            <#elseif message.type == 'info'>
                                alert-info
                            <#else>
                                alert-danger
                            </#if>"
                            role="alert"
                        >
                            <#if message.summary??>
                                ${kcSanitize(message.summary)?no_esc}
                            </#if>
                        </div>
                    </#if>

                    <form id="kc-passwd-update-form" action="${url.loginAction}" method="post">
                        <div class="mb-3">
                            <label for="password-new" class="form-label">
                                New password
                            </label>

                            <div class="input-group">
                                <input id="password-new" class="form-control" type="password" name="password-new" placeholder="Enter new password" autocomplete="new-password" autofocus required>
                                <button class="btn btn-outline-secondary" type="button" id="toggle-new-password" aria-label="Show or hide new password">
                                    <i id="new-password-icon" class="bi bi-eye"></i>
                                </button>
                            </div>

                            <#if messagesPerField??>
                                <#if messagesPerField.existsError("password")>
                                    <div class="text-danger small mt-1">
                                        ${kcSanitize(
                                            messagesPerField.get("password")
                                        )?no_esc}
                                    </div>
                                </#if>
                            </#if>
                        </div>

                        <div class="mb-3">
                            <label for="password-confirm" class="form-label">
                                Confirm new password
                            </label>

                            <div class="input-group">
                                <input id="password-confirm" class="form-control" type="password" name="password-confirm" placeholder="Confirm new password" 
                                	autocomplete="new-password" required>
                                <button class="btn btn-outline-secondary" type="button" id="toggle-confirm-password" aria-label="Show or hide confirmed password">
                                    <i id="confirm-password-icon" class="bi bi-eye"></i>
                                </button>
                            </div>

                            <#if messagesPerField??>
                                <#if messagesPerField.existsError(
                                    "password-confirm"
                                )>
                                    <div class="text-danger small mt-1">
                                        ${kcSanitize(
                                            messagesPerField.get(
                                                "password-confirm"
                                            )
                                        )?no_esc}
                                    </div>
                                </#if>
                            </#if>
                        </div>

                        <#if isAppInitiatedAction??>
                            <div class="form-check mb-3">
                                <input id="logout-sessions" class="form-check-input" type="checkbox" name="logout-sessions" value="on" checked>
                                <label class="form-check-label small" for="logout-sessions">
                                    Sign out from other devices
                                </label>
                            </div>
                        </#if>

                        <div class="d-grid gap-2">
                            <button id="kc-passwd-update-form-submit" class="btn btn-primary" type="submit" name="submitAction" value="Save">
                                <i class="bi bi-shield-lock me-1"></i>
                                Update password
                            </button>

                            <#if isAppInitiatedAction??>
                                <button class="btn btn-outline-secondary" type="submit" name="cancel-aia" value="true" formnovalidate>
                                    Cancel
                                </button>
                            </#if>
                        </div>
                    </form>

                    <div class="mt-3 text-center">
                        <small class="text-muted">
                            Use a strong password that you do not use
                            for another account.
                        </small>
                    </div>

                </div>
            </div>

            <p class="text-center mt-3 text-muted small">
                Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.
            </p>

        </div>
    </div>
</div>

<script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>

<script>
    function configurePasswordToggle(buttonId, inputId, iconId) {
        const button = document.getElementById(buttonId);
        const input = document.getElementById(inputId);
        const icon = document.getElementById(iconId);

        if (!button || !input || !icon) {
            return;
        }

        button.addEventListener("click", function () {
            const hidden = input.type === "password";

            input.type = hidden ? "text" : "password";

            icon.classList.toggle("bi-eye", !hidden);
            icon.classList.toggle("bi-eye-slash", hidden);
        });
    }

    configurePasswordToggle(
        "toggle-new-password",
        "password-new",
        "new-password-icon"
    );

    configurePasswordToggle(
        "toggle-confirm-password",
        "password-confirm",
        "confirm-password-icon"
    );
</script>

</body>
</html>
