<#-- Pending-approval denials reuse this error page; detect that case locale-safely
     by comparing the summary against the resolved pendingApprovalMessage key. -->
<#assign isPendingApproval = message?? && message?has_content && message.summary?has_content
         && message.summary == msg("pendingApprovalMessage")>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><#if isPendingApproval>Account Pending Approval<#else>Application Unavailable</#if> | Dlula</title>

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

                        <!-- SANSA LOGO -->
                        <img src="${url.resourcesPath}/img/desa-logo.png"
                             alt="DESA"
                             class="img-fluid mb-3"
                             style="max-height: 120px;">

                        <!-- DETERMINE APPLICATION NAME DYNAMICALLY -->
                        <#assign appName = "Decision Support Tool">
                        <#if client??>
                            <#if client.name?? && client.name?has_content>
                                <#assign appName = advancedMsg(client.name)>
                            <#elseif client.clientId?? && client.clientId?has_content>
                                <#assign appName = client.clientId>
                            </#if>
                        </#if>

                        <#-- "Unavailable" is misleading for a pending-approval denial -- the
                             app is fine, the account just isn't approved yet. isPendingApproval
                             is computed at the top of this template. -->
                        <#if isPendingApproval>
                            <!-- PENDING APPROVAL ICON -->
                            <div class="status-icon mb-3">
                                <i class="bi bi-hourglass-split text-primary fs-1"></i>
                            </div>

                            <!-- HEADING -->
                            <h4 class="fw-bold mb-3">
                                Account Pending Approval
                            </h4>

                            <div class="alert alert-info text-start">
                                ${kcSanitize(message.summary)?no_esc}
                            </div>
                        <#else>
                        <!-- ERROR ICON -->
                        <div class="status-icon error mb-3">
                            <i class="bi bi-exclamation-triangle-fill text-danger fs-1"></i>
                        </div>

                        <!-- HEADING -->
                        <h4 class="fw-bold text-danger mb-3">
                            ${appName} Unavailable
                        </h4>

                        <!-- SIMPLE MESSAGE -->
                        <#if message?has_content && message.summary?has_content>
                            <div class="alert alert-warning text-center text-start">
                                ${kcSanitize(message.summary)?no_esc}
                            </div>
                        <#else>
                            <div class="alert alert-warning text-start">
                                <strong>${appName}</strong> is currently unavailable.
                                <br><br>
                                Please try again later.
                                <br><br>
                                If the issue persists, contact the SANSA system administrator.
                            </div>
                        </#if>
                        </#if>

                        <!-- ERROR REFERENCE -->
                        <#if traceId?? && traceId?has_content>
                            <div class="small text-muted mb-3">
                                Error Reference: <code>${traceId}</code>
                            </div>
                        </#if>

                        <!-- BUTTONS -->
                        <div class="d-grid gap-2">

                            <!-- Return to Application -->
                            <#if client?? && client.baseUrl?? && client.baseUrl?has_content>
                                <a href="${client.baseUrl}" class="btn btn-primary">
                                    <i class="bi bi-house-door me-2"></i> Return to Application
                                </a>
                            </#if>

                            <!-- Try Again -->
                            <#if url?? && url.loginRestartFlowUrl?? && url.loginRestartFlowUrl?has_content>
                                <a href="${url.loginRestartFlowUrl}" class="btn btn-outline-secondary">
                                    <i class="bi bi-arrow-clockwise me-2"></i> Try Again
                                </a>
                            </#if>

                        </div>

                    </div>
                </div>

            </div>
        </div>
    </div>

    <!-- FOOTER -->
    <footer class="site-footer">
        <div class="site-footer-inner">
            <img src="${url.resourcesPath}/img/dsti-footer.jpg" alt="Department of Science, Technology and Innovation" class="site-footer-logo site-footer-logo--sti">
            <p class="site-footer-copyright">Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.</p>
            <img src="${url.resourcesPath}/img/sansa-footer.png" alt="SANSA" class="site-footer-logo">
        </div>
    </footer>

    <!-- BOOTSTRAP JAVASCRIPT -->
    <script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>

</body>

</html>