<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Verify Your Email | Dlula</title>
	
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
                <div class="card-body p-4 p-md-5">

		
		    <div class="text-center mb-4">
                        <img src="${url.resourcesPath}/img/SANSA.jpg" alt="Dlula" class="img-fluid mb-3" style="max-height: 80px;">
                        <h4 class="fw-bold">Verify Your Email Address</h4>
                        
                        <p class="text-muted mb-0">
                            Your account must be verified before you can continue.
                        </p>
                    </div>	

                    <#if message?has_content>
                        <div class="alert
                            <#if message.type = 'success'>
                                alert-success
                            <#elseif message.type = 'warning'>
                                alert-warning
                            <#else>
                                alert-danger
                            </#if>
                            text-center">

                            ${kcSanitize(message.summary)?no_esc}
                        </div>
                    </#if>

                    <div class="alert alert-info text-center">
                        <i class="bi bi-info-circle me-1"></i>

                        A verification link will be sent to:

                        <#if user?? && user.email??>
                            <div class="fw-bold mt-2">
                                ${user.email}
                            </div>
                        <#else>
                            <div class="mt-2">
                                your registered email address
                            </div>
                        </#if>
                    </div>

                    <form
                        id="kc-verify-email-form"
                        action="${url.loginAction}"
                        method="post">

                        <div class="d-grid gap-2">
                            <button
                                type="submit"
                                name="submitAction"
                                value="resend"
                                class="btn btn-primary">

                                <i class="bi bi-send me-1"></i>
                                Send verification email
                            </button>
                        </div>
                    </form>

                    <#if client?? && client.baseUrl??>
                        <div class="text-center mt-3 backto">
                            <a href="${client.baseUrl}" class="text-decoration-none">
				<i class="bi bi-arrow-left me-1"></i>
                                Back to application
                            </a>
                        </div>
                    </#if>

                </div>
            </div>

            <p class="text-center mt-3 text-muted small">
                Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.
            </p>

        </div>
    </div>
</div>

<script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>
</body>
</html>
