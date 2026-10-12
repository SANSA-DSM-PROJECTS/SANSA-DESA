<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Update Profile | Dlula</title>
	
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex align-items-center min-vh-100">

<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-7 col-lg-5">

            <div class="card shadows rounded-4">
                <div class="card-body p-4">

                    <div class="text-center mb-4">
                        <img
                            src="${url.resourcesPath}/img/SANSA.jpg"
                            alt="Dlula"
                            class="img-fluid mb-3"
                            style="max-height: 80px;"
                        >

                        <h4 class="fw-bold mb-2">
                            Update Profile
                        </h4>

                        <p class="profile-description small mb-0">
                            Confirm or update your personal information
                            before continuing.
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

                    <form
                        id="kc-update-profile-form"
                        action="${url.loginAction}"
                        method="post"
                    >

                        <#list profile.attributes as attribute>

                            <#assign fieldName = attribute.name>
                            <#assign fieldValue = (attribute.value!'')>
                            <#assign fieldLabel = attribute.displayName!attribute.name>
                            <#assign requiredField = attribute.required>

                            <div class="mb-3">

                                <label
                                    for="${fieldName}"
                                    class="form-label"
                                >
                                    ${fieldLabel}

                                    <#if requiredField>
                                        <span class="text-danger">*</span>
                                    </#if>
                                </label>

                                <#if attribute.annotations.inputType?? &&
                                     attribute.annotations.inputType == "textarea">

                                    <textarea
                                        id="${fieldName}"
                                        name="${fieldName}"
                                        class="form-control"
                                        rows="4"
                                        <#if requiredField>required</#if>
                                        <#if attribute.readOnly>readonly</#if>
                                    >${fieldValue}</textarea>

                                <#elseif attribute.annotations.inputType?? &&
                                         attribute.annotations.inputType == "select" &&
                                         attribute.validators.options??>

                                    <select
                                        id="${fieldName}"
                                        name="${fieldName}"
                                        class="form-select"
                                        <#if requiredField>required</#if>
                                        <#if attribute.readOnly>disabled</#if>
                                    >
                                        <option value="">
                                            Select ${fieldLabel}
                                        </option>

                                        <#list attribute.validators.options.options as option>
                                            <option
                                                value="${option}"
                                                <#if fieldValue == option>
                                                    selected
                                                </#if>
                                            >
                                                ${option}
                                            </option>
                                        </#list>
                                    </select>

                                <#else>

                                    <#assign inputType = "text">

                                    <#if fieldName == "email">
                                        <#assign inputType = "email">
                                    <#elseif attribute.annotations.inputType??>
                                        <#assign inputType = attribute.annotations.inputType>
                                    </#if>

                                    <div class="input-group">

                                        <span class="input-group-text">
                                            <#if fieldName == "username">
                                                <i class="bi bi-person"></i>
                                            <#elseif fieldName == "email">
                                                <i class="bi bi-envelope"></i>
                                            <#elseif fieldName == "firstName">
                                                <i class="bi bi-person-badge"></i>
                                            <#elseif fieldName == "lastName">
                                                <i class="bi bi-person-vcard"></i>
                                            <#elseif fieldName == "organisation">
                                                <i class="bi bi-building"></i>
                                            <#elseif fieldName == "phone" ||
                                                     fieldName == "phoneNumber">
                                                <i class="bi bi-telephone"></i>
                                            <#else>
                                                <i class="bi bi-pencil-square"></i>
                                            </#if>
                                        </span>

                                        <input
                                            id="${fieldName}"
                                            name="${fieldName}"
                                            class="form-control"
                                            type="${inputType}"
                                            value="${fieldValue}"
                                            placeholder="Enter ${fieldLabel?lower_case}"
                                            <#if requiredField>required</#if>
                                            <#if attribute.readOnly>readonly</#if>
                                            <#if fieldName == "username">
                                                autocomplete="username"
                                            <#elseif fieldName == "email">
                                                autocomplete="email"
                                            <#elseif fieldName == "firstName">
                                                autocomplete="given-name"
                                            <#elseif fieldName == "lastName">
                                                autocomplete="family-name"
                                            </#if>
                                        >

                                    </div>

                                </#if>

                                <#if messagesPerField?? &&
                                     messagesPerField.existsError(fieldName)>

                                    <div class="text-danger small mt-1">
                                        <i class="bi bi-exclamation-circle me-1"></i>

                                        ${kcSanitize(
                                            messagesPerField.get(fieldName)
                                        )?no_esc}
                                    </div>

                                </#if>

                                <#if attribute.annotations.inputHelperTextBefore??>
                                    <div class="form-text">
                                        ${attribute.annotations.inputHelperTextBefore}
                                    </div>
                                </#if>

                            </div>

                        </#list>

                        <div class="d-grid gap-2 mt-4">

                            <button
                                id="kc-update-profile-form-submit"
                                class="btn btn-primary"
                                type="submit"
                            >
                                <i class="bi bi-person-check me-1"></i>
                                Save profile
                            </button>

                            <#if isAppInitiatedAction??>
                                <button
                                    class="btn btn-outline-secondary"
                                    type="submit"
                                    name="cancel-aia"
                                    value="true"
                                    formnovalidate
                                >
                                    <i class="bi bi-x-circle me-1"></i>
                                    Cancel
                                </button>
                            </#if>

                        </div>

                    </form>

                    <div class="profile-security-note mt-3 text-center">
                        <small>
                            <i class="bi bi-shield-check me-1"></i>
                            Your personal information is securely managed
                            through our authentication.
                        </small>
                    </div>

                </div>
            </div>

            <p class="page-copyright text-center mt-3 small">
                Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.
            </p>

        </div>
    </div>
</div>

<script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>

</body>
</html>
