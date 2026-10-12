<#import "template.ftl" as layout>
<#import "user-profile-commons.ftl" as userProfileCommons>

<@layout.registrationLayout
    displayMessage=messagesPerField.exists('global')
    displayRequiredFields=false
    ; section>

<#if section == "header">
    ${msg("registerTitle")}

<#elseif section == "form">

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Create Account | SANSA DST</title>
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex align-items-center min-vh-100">

<div class="container mt-4">
    <div class="row justify-content-center">
        <div class="col-md-6 col-lg-5">

            <div class="card shadows rounded-4">
                <div class="card-body p-4">

                    <div class="text-center mb-4">
                        <img src="${url.resourcesPath}/img/SANSA.jpg"
                             alt="SANSA"
                             class="img-fluid mb-3"
                             style="max-height: 80px;">
                        <h4 class="fw-bold">Create Account</h4>
                    </div>

                    <#if messagesPerField.exists('global')>
                        <div class="alert alert-danger py-2" role="alert">
                            ${kcSanitize(messagesPerField.get('global'))?no_esc}
                        </div>
                    </#if>

                    <form id="kc-register-form"
                          action="${url.registrationAction}"
                          method="post">

                        <!-- Email Field (used as the username when email-as-username is enabled) -->
                        <div class="mb-3">
                            <label for="email" class="form-label">Email address *</label>
                            <input type="email"
                                   class="form-control <#if messagesPerField.existsError('email')>is-invalid</#if>"
                                   id="email" name="email"
                                   value="${(register.formData.email!'')}"
                                   autocomplete="email" autofocus required>
                            <#if messagesPerField.existsError('email')>
                                <div class="invalid-feedback">
                                    ${kcSanitize(messagesPerField.get('email'))?no_esc}
                                </div>
                            </#if>
                        </div>

                        <!-- Username Field: only shown when email is NOT used as the username -->
                        <#if !realm.registrationEmailAsUsername>
                            <div class="mb-3">
                                <label for="username" class="form-label">Username *</label>
                                <input type="text"
                                       class="form-control <#if messagesPerField.existsError('username')>is-invalid</#if>"
                                       id="username" name="username"
                                       value="${(register.formData.username!'')}"
                                       autocomplete="username" required>
                                <#if messagesPerField.existsError('username')>
                                    <div class="invalid-feedback">
                                        ${kcSanitize(messagesPerField.get('username'))?no_esc}
                                    </div>
                                </#if>
                            </div>
                        </#if>

                        <!-- First + Last name on one row -->
                        <div class="row g-3">
                            <div class="col-sm-6 mb-3">
                                <label for="firstName" class="form-label">First name *</label>
                                <input type="text"
                                       class="form-control <#if messagesPerField.existsError('firstName')>is-invalid</#if>"
                                       id="firstName" name="firstName"
                                       value="${(register.formData.firstName!'')}"
                                       autocomplete="given-name" required>
                                <#if messagesPerField.existsError('firstName')>
                                    <div class="invalid-feedback">
                                        ${kcSanitize(messagesPerField.get('firstName'))?no_esc}
                                    </div>
                                </#if>
                            </div>

                            <div class="col-sm-6 mb-3">
                                <label for="lastName" class="form-label">Last name *</label>
                                <input type="text"
                                       class="form-control <#if messagesPerField.existsError('lastName')>is-invalid</#if>"
                                       id="lastName" name="lastName"
                                       value="${(register.formData.lastName!'')}"
                                       autocomplete="family-name" required>
                                <#if messagesPerField.existsError('lastName')>
                                    <div class="invalid-feedback">
                                        ${kcSanitize(messagesPerField.get('lastName'))?no_esc}
                                    </div>
                                </#if>
                            </div>
                        </div>

                        <!-- Organisation Field: dropdown of known bodies + "Other" free text.
                             The value Keycloak saves lives in the hidden #organization input
                             (the user-profile attribute). JS keeps it in sync with the
                             visible controls; the current value is preserved on validation errors. -->
                        <#assign orgValue = (register.formData.organization!'')>
                        <#-- Known organisations. Keep this list in sync across environments. -->
                        <#assign knownOrgs = [
                            "South African National Space Agency (SANSA)",
                            "Department of Water and Sanitation (DWS)",
                            "Water Research Commission (WRC)",
                            "Rand Water",
                            "Umgeni-uThukela Water",
                            "Department of Forestry, Fisheries and the Environment (DFFE)",
                            "South African National Biodiversity Institute (SANBI)",
                            "South African Weather Service (SAWS)",
                            "Council for Scientific and Industrial Research (CSIR)",
                            "Statistics South Africa (Stats SA)",
                            "Department of Agriculture, Land Reform and Rural Development (DALRRD)",
                            "South African National Parks (SANParks)",
                            "Department of Cooperative Governance and Traditional Affairs (COGTA)",
                            "National Disaster Management Centre (NDMC)",
                            "Provincial Disaster Management Centre",
                            "City of Cape Town",
                            "City of Johannesburg",
                            "City of Tshwane",
                            "City of Ekurhuleni",
                            "eThekwini Municipality",
                            "Nelson Mandela Bay Municipality",
                            "Buffalo City Municipality",
                            "Mangaung Municipality",
                            "Local or District Municipality",
                            "University or Research Institution"
                        ]>
                        <#-- Is the saved value one of the known options, or a custom "Other"? -->
                        <#assign isOther = orgValue?has_content && !knownOrgs?seq_contains(orgValue)>

                        <div class="mb-3">
                            <label for="organization-select" class="form-label">Organisation *</label>
                            <select id="organization-select"
                                    class="form-select <#if messagesPerField.existsError('organization')>is-invalid</#if>">
                                <option value="" <#if !orgValue?has_content>selected</#if> disabled>
                                    Select your organisation…
                                </option>
                                <#list knownOrgs as org>
                                    <option value="${org}" <#if orgValue == org>selected</#if>>${org}</option>
                                </#list>
                                <option value="__other__" <#if isOther>selected</#if>>Other (not listed)</option>
                            </select>

                            <!-- Free-text box, shown only when "Other" is selected -->
                            <input type="text"
                                   id="organization-other"
                                   class="form-control mt-2 <#if !isOther>d-none</#if>"
                                   placeholder="Enter your organisation name"
                                   value="<#if isOther>${orgValue}</#if>">

                            <!-- The actual value Keycloak saves -->
                            <input type="hidden" id="organization" name="organization" value="${orgValue}">

                            <#if messagesPerField.existsError('organization')>
                                <div class="invalid-feedback d-block">
                                    ${kcSanitize(messagesPerField.get('organization'))?no_esc}
                                </div>
                            </#if>
                        </div>

                        <!-- Password Field with show/hide toggle -->
                        <div class="mb-3">
                            <label for="password" class="form-label">Password *</label>
                            <div class="input-group">
                                <input type="password"
                                       class="form-control <#if messagesPerField.existsError('password')>is-invalid</#if>"
                                       id="password" name="password"
                                       autocomplete="new-password" required>
                                <button class="btn btn-outline-secondary" type="button"
                                        id="toggle-password" tabindex="-1"
                                        aria-label="Show password">
                                    <i class="bi bi-eye" id="password-icon"></i>
                                </button>
                                <#if messagesPerField.existsError('password')>
                                    <div class="invalid-feedback">
                                        ${kcSanitize(messagesPerField.get('password'))?no_esc}
                                    </div>
                                </#if>
                            </div>
                        </div>

                        <!-- Password Confirm Field with show/hide toggle -->
                        <div class="mb-3">
                            <label for="password-confirm" class="form-label">Confirm password *</label>
                            <div class="input-group">
                                <input type="password"
                                       class="form-control <#if messagesPerField.existsError('password-confirm')>is-invalid</#if>"
                                       id="password-confirm" name="password-confirm"
                                       autocomplete="new-password" required>
                                <button class="btn btn-outline-secondary" type="button"
                                        id="toggle-password-confirm" tabindex="-1"
                                        aria-label="Show password">
                                    <i class="bi bi-eye" id="password-confirm-icon"></i>
                                </button>
                                <#if messagesPerField.existsError('password-confirm')>
                                    <div class="invalid-feedback">
                                        ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}
                                    </div>
                                </#if>
                            </div>
                        </div>

                        <div class="d-grid mt-4">
                            <button type="submit" id="kc-register" class="btn btn-primary btn-lg">
                                Register
                            </button>
                        </div>

                        <div class="text-center backto small mt-3">
                            <a href="${url.loginUrl}" class="text-decoration-none">
                                ← Back to login
                            </a>
                        </div>

                    </form>

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
    // Show / hide password toggles
    function wireToggle(btnId, inputId, iconId) {
        var btn = document.getElementById(btnId);
        var input = document.getElementById(inputId);
        var icon = document.getElementById(iconId);
        if (!btn || !input || !icon) return;
        btn.addEventListener("click", function () {
            var show = input.type === "password";
            input.type = show ? "text" : "password";
            icon.classList.toggle("bi-eye", !show);
            icon.classList.toggle("bi-eye-slash", show);
            btn.setAttribute("aria-label", show ? "Hide password" : "Show password");
        });
    }
    wireToggle("toggle-password", "password", "password-icon");
    wireToggle("toggle-password-confirm", "password-confirm", "password-confirm-icon");

    // Organisation dropdown + "Other" free text -> hidden #organization field
    (function () {
        var select = document.getElementById("organization-select");
        var other = document.getElementById("organization-other");
        var hidden = document.getElementById("organization");
        if (!select || !other || !hidden) return;

        function sync() {
            if (select.value === "__other__") {
                other.classList.remove("d-none");
                other.required = true;
                hidden.value = other.value.trim();
            } else {
                other.classList.add("d-none");
                other.required = false;
                hidden.value = select.value;
            }
        }
        select.addEventListener("change", sync);
        other.addEventListener("input", sync);
        sync(); // set initial state (e.g. after a validation error)
    })();

    // Prevent double submission
    document.getElementById("kc-register-form").addEventListener("submit", function () {
        var btn = document.getElementById("kc-register");
        btn.disabled = true;
        btn.textContent = "Creating account...";
    });
</script>
</body>
</html>

<#elseif section == "title">
    Create Account | SANSA DST
</#if>
</@layout.registrationLayout>
