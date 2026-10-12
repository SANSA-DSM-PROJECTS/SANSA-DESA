<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title> Account Information | Dlula</title>
	
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">
	
    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex flex-column min-vh-100">

<div class="container flex-grow-1 d-flex align-items-center">
    <div class="row justify-content-center w-100">
        <div class="col-md-6 col-lg-5">

            <div class="card shadow rounded-4 border-0">
                <div class="card-body p-4 p-md-5 text-center">

                    <img
                        src="${url.resourcesPath}/img/desa-logo.png"
                        alt="DESA"
                        class="img-fluid mb-3"
                        style="max-height: 120px;"
                    >

                    <div class="status-icon success mb-3">
                        <i class="bi bi-check-circle"></i>
                    </div>

                    <h4 class="fw-bold mb-3">
                        <#if messageHeader??>
                            ${kcSanitize(msg(messageHeader))?no_esc}
                        <#else>
                            Request completed
                        </#if>
                    </h4>

                    <#if message?has_content>
                        <div class="alert
                            <#if message.type = 'success'>
                                alert-success
                            <#elseif message.type = 'warning'>
                                alert-warning
                            <#elseif message.type = 'error'>
                                alert-danger
                            <#else>
                                alert-info
                            </#if>">

                            ${kcSanitize(message.summary)?no_esc}
                        </div>
                    </#if>

                    <#if requiredActions??>
                        <div class="text-start alert alert-warning">
                            <strong>Required actions:</strong>

                            <ul class="mb-0 mt-2">
                                <#list requiredActions as requiredAction>
                                    <li>
                                        ${kcSanitize(msg("requiredAction.${requiredAction}"))?no_esc}
                                    </li>
                                </#list>
                            </ul>
                        </div>
                    </#if>

                    <#if pageRedirectUri?? && pageRedirectUri?has_content>
                        <div class="d-grid">
                            <a
                                href="${pageRedirectUri}"
                                class="btn btn-primary">

                                Continue to application
                            </a>
                        </div>

                    <#elseif actionUri?? && actionUri?has_content>
                        <div class="d-grid">
                            <a
                                href="${actionUri}"
                                class="btn btn-primary">

                                Continue
                            </a>
                        </div>

                    <#elseif client?? && client.baseUrl??>
                        <div class="d-grid">
                            <a
                                href="${client.baseUrl}"
                                class="btn btn-primary">

                                Return to application
                            </a>
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
