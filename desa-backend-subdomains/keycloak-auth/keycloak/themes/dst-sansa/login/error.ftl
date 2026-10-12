<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Application Unavailable | Dlula</title>

    <link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex align-items-center min-vh-100">

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-6 col-lg-5">

                <div class="card shadow rounded-4 border-0">
                    <div class="card-body p-4 p-md-5 text-center">

                        <!-- SANSA LOGO -->
                        <img src="${url.resourcesPath}/img/SANSA.jpg"
                             alt="SANSA"
                             class="img-fluid mb-3"
                             style="max-height: 80px;">

                        <!-- DETERMINE APPLICATION NAME DYNAMICALLY -->
                        <#assign appName = "Decision Support Tool">
                        <#if client??>
                            <#if client.name?? && client.name?has_content>
                                <#assign appName = advancedMsg(client.name)>
                            <#elseif client.clientId?? && client.clientId?has_content>
                                <#assign appName = client.clientId>
                            </#if>
                        </#if>

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

                <!-- FOOTER -->
                <p class="text-center mt-3 text-muted small">
                    Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.
                </p>

            </div>
        </div>
    </div>

    <!-- BOOTSTRAP JAVASCRIPT -->
    <script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>

</body>

</html>